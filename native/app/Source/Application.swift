//
//  Application.swift
//  eqMac
//
//  Created by Roman Kisil on 22/01/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Foundation
import Cocoa
import AMCoreAudio
import Dispatch
import EmitterKit
import AVFoundation
import SwiftyUserDefaults
import SwiftyJSON
import ServiceManagement
import ReSwift
import Sparkle
import Shared

enum VolumeChangeDirection: String {
  case UP = "UP"
  case DOWN = "DOWN"
}

class Application {
  static var bundleId: String {
    return Bundle.main.bundleIdentifier!
  }
  static var engine: Engine?
  static var output: Output?
  static var engineCreated = EmitterKit.Event<Void>()
  static var outputCreated = EmitterKit.Event<Void>()

  static var selectedDevice: AudioDevice?
  static var lastKnownInputDevice: AudioDevice?
  static var selectedDeviceIsAliveListener: EventListener<AudioDevice>?
  static var selectedDeviceVolumeChangedListener: EventListener<AudioDevice>?
  static var selectedDeviceSampleRateChangedListener: EventListener<AudioDevice>?
  static var justChangedSelectedDeviceVolume = false
  static var lastKnownDeviceStack: [AudioDevice] = []

  static let audioPipelineIsRunning = EmitterKit.Event<Void>()
  static let audioTransitionCompleted = EmitterKit.Event<Bool>()
  static var audioPipelineIsRunningListener: EmitterKit.EventListener<Void>?
  static var audioTransitionInFlight = false
  private static var ignoreEvents = false
  private static var ignoreVolumeEvents = false

  static var settings: Settings!
    
    
  static var ui: UI!
    
    

  static var dataBus: ApplicationDataBus!
  static let error = EmitterKit.Event<String>()
  
  static var updater = SUUpdater(for: Bundle.main)!
  
  static let store: Store = Store(
    reducer: ApplicationStateReducer,
    state: ApplicationState.load(),
    middleware: []
  )

  static let enabledChanged = EmitterKit.Event<Bool>()
  static var enabledChangedListener: EmitterKit.EventListener<Bool>?
  static var enabled = store.state.enabled {
    didSet {
      if (oldValue != enabled) {
        Console.log("Application.enabled didSet", "old=\(oldValue)", "new=\(enabled)")
        enabledChanged.emit(enabled)
      }
    }
  }
  
  static var equalizersTypeChangedListener: EventListener<EqualizerType>?

  private static func applyProcessingEnabledState(_ enabled: Bool) {
    Console.log("applyProcessingEnabledState", "enabled=\(enabled)")
    engine?.equalizers.enabled = enabled
  }

  static public func start () {
    Console.log(
      "Application.start",
      "store.enabled=\(store.state.enabled)",
      "enabled=\(enabled)",
      "driver.installed=\(Driver.isInstalled)",
      "driver.pluginId=\(String(describing: Driver.pluginId))",
      "driver.deviceId=\(String(describing: Driver.device?.id))"
    )
    self.settings = Settings()

    Networking.startMonitor()
    
    Driver.check {
      Console.log(
        "Driver.check completed",
        "store.enabled=\(store.state.enabled)",
        "enabled=\(enabled)",
        "inputPermission=\(InputSource.hasPermission)"
      )
      Sources.getInputPermission {
        Console.log(
          "Input permission callback",
          "store.enabled=\(store.state.enabled)",
          "enabled=\(enabled)"
        )
        AudioHardware.sharedInstance.enableDeviceMonitoring()
        setupAudio {
          applyProcessingEnabledState(enabled)
        }

        setupListeners()

        self.setupUI {
          if (User.isFirstLaunch) {
            UI.show()
          } else {
            UI.close()
          }
        }
      }
    }
  }

  private static func setupListeners () {
    enabledChangedListener = enabledChanged.on { enabled in
      Console.log("enabledChanged listener", "enabled=\(enabled)")
      DispatchQueue.main.async {
        if engine == nil || output == nil {
          setupAudio {
            applyProcessingEnabledState(enabled)
            audioTransitionInFlight = false
            audioTransitionCompleted.emit(enabled)
          }
        } else {
          applyProcessingEnabledState(enabled)
          audioTransitionInFlight = false
          audioTransitionCompleted.emit(enabled)
        }
      }
    }
    
    equalizersTypeChangedListener = Equalizers.typeChanged.on { _ in
      if (enabled) {
        rebuildAudioPipeline()
      }
      
    }
  }
  
  private static var settingUpAudio = false
  private static func setupAudio (_ completion: (() -> Void)? = nil) {
    if (settingUpAudio) { return }
    settingUpAudio = true
    Console.log("Setting up Audio Engine")
    Driver.show {
      setupDeviceEvents()
      startPassthrough {
        settingUpAudio = false
        applyProcessingEnabledState(enabled)
        completion?()
      }
    }
  }
  
  static var ignoreNextVolumeEvent = false
  
  static func setupDeviceEvents () {
    AudioDeviceEvents.on(.outputChanged) { device in
      if device.id == Driver.device!.id { return }

      if Outputs.isDeviceAllowed(device) {
        if ignoreEvents {
          dataBus?.send(to: "/outputs/selected", data: JSON([ "id": device.id ]))
          return
        }
        Console.log("outputChanged: ", device, " starting PlayThrough")
        startPassthrough()
      } else {
        // TODO: Tell the user eqMac doesn't support this device
      }
    }
    
    AudioDeviceEvents.onDeviceListChanged { list in
      if ignoreEvents { return }
      Console.log("listChanged", list)
      
      if list.added.count > 0 {
        for added in list.added {
          if Outputs.shouldAutoSelect(added) {
            selectOutput(device: added)
            break
          }
        }
      } else if (list.removed.count > 0) {
        
        let currentDeviceRemoved = list.removed.contains(where: { $0.id == selectedDevice?.id })
        
        if (currentDeviceRemoved) {
          ignoreEvents = true
          removeEngines()
          try! AudioDeviceEvents.recreateEventEmitters([.isAliveChanged, .volumeChanged, .nominalSampleRateChanged])
          self.setupDriverDeviceEvents()
          Async.delay(500) {
            selectOutput(device: getLastKnowDeviceFromStack())
          }
        }
      }
      
    }
    AudioDeviceEvents.on(.isJackConnectedChanged) { device in
      if ignoreEvents { return }
      let connected = device.isJackConnected(direction: .playback)
      Console.log("isJackConnectedChanged", device, connected)
      if (device.id != selectedDevice?.id) {
        if (connected == true) {
          selectOutput(device: device)
        }
      } else {
        stopRemoveEngines {
          Async.delay(1000) {
            // need a delay, because emitter should finish its work at first
            try! AudioDeviceEvents.recreateEventEmitters([.isAliveChanged, .volumeChanged, .nominalSampleRateChanged])
            setupDriverDeviceEvents()
            matchDriverSampleRateToOutput()
            createAudioPipeline()
          }
        }
      }
    }
    
    setupDriverDeviceEvents()
  }
  
  static var ignoreNextDriverMuteEvent = false
  static func setupDriverDeviceEvents () {
    AudioDeviceEvents.on(.volumeChanged, onDevice: Driver.device!) {
      if ignoreEvents || ignoreVolumeEvents {
        return
      }
      
      if ignoreNextVolumeEvent {
        ignoreNextVolumeEvent = false
        return
      }
      if (overrideNextVolumeEvent) {
        overrideNextVolumeEvent = false
        ignoreNextVolumeEvent = true
        Driver.device!.setVirtualMasterVolume(1, direction: .playback)
        return
      }
      let gain = Double(Driver.device!.virtualMasterVolume(direction: .playback)!)
      if (gain <= 1 && gain != Application.store.state.volume.gain) {
        Application.dispatchAction(VolumeAction.setGain(gain, false))
      }

    }
    
    AudioDeviceEvents.on(.muteChanged, onDevice: Driver.device!) {
      if ignoreEvents { return }
      if (ignoreNextDriverMuteEvent) {
        ignoreNextDriverMuteEvent = false
        return
      }
      Application.dispatchAction(VolumeAction.setMuted(Driver.device!.mute))
    }
  }
  
  static func selectOutput (device: AudioDevice) {
    ignoreEvents = true
    stopRemoveEngines {
      Async.delay(500) {
        ignoreEvents = false
        AudioDevice.currentOutputDevice = device
      }
    }
  }

  static var startingPassthrough = false
  static func startPassthrough (_ completion: (() -> Void)? = nil) {
    if (startingPassthrough) {
      completion?()
      return
    }

    startingPassthrough = true
    selectedDevice = AudioDevice.currentOutputDevice

    if (selectedDevice!.id == Driver.device!.id) {
      selectedDevice = getLastKnowDeviceFromStack()
    }

    lastKnownDeviceStack.append(selectedDevice!)
    stabilizeInputDeviceForSelectedOutput()

    ignoreEvents = true
    var volume: Double = Application.store.state.volume.gain
    var muted = store.state.volume.muted
    var balance = store.state.volume.balance

    if (selectedDevice!.outputVolumeSupported) {
      volume = Double(selectedDevice!.virtualMasterVolume(direction: .playback)!)
      muted = selectedDevice!.mute
    }

    if (selectedDevice!.outputBalanceSupported) {
      balance = Double(selectedDevice!.virtualMasterBalance(direction: .playback)!).remap(
        inMin: 0,
        inMax: 1,
        outMin: -1,
        outMax: 1
      )
    }

    Application.dispatchAction(VolumeAction.setBalance(balance, false))
    Application.dispatchAction(VolumeAction.setGain(volume, false))
    Application.dispatchAction(VolumeAction.setMuted(muted))
    
    Driver.device!.setVirtualMasterVolume(volume > 1 ? 1 : Float32(volume), direction: .playback)
    Driver.latency = selectedDevice!.latency(direction: .playback) ?? 0 // Set driver latency to mimic device
    Driver.name = "\(selectedDevice!.sourceName ?? selectedDevice!.name) (eqMac)"
    self.matchDriverSampleRateToOutput()
    
    Console.log("Driver new Latency: \(Driver.latency)")
    Console.log("Driver new Sample Rate: \(Driver.device!.actualSampleRate())")
    Console.log("Driver new name: \(Driver.name)")

    AudioDevice.currentOutputDevice = Driver.device!
    AudioDevice.currentSystemDevice = Driver.device!

    waitForDriverActivation {
      ignoreEvents = false
      createAudioPipeline()
      startingPassthrough = false
      completion?()
    }
  }

  private static func waitForDriverActivation (timeoutMs: UInt = 3000, pollMs: UInt = 50, completion: @escaping () -> Void) {
    var startedAt = Time.stamp
    var didRetryWithDriverReset = false

    func finishIfReady () {
      let currentOutputDevice = AudioDevice.defaultOutputDevice()
      let currentOutputId = currentOutputDevice?.id
      let driverId = Driver.device?.id

      if currentOutputId == driverId, Driver.hidden == false {
        Console.log(
          "waitForDriverActivation ready",
          "currentOutputId=\(String(describing: currentOutputId))",
          "driverId=\(String(describing: driverId))",
          "hidden=\(Driver.hidden)"
        )
        completion()
        return
      }

      if Time.stamp - startedAt >= timeoutMs {
        if !didRetryWithDriverReset {
          didRetryWithDriverReset = true
          startedAt = Time.stamp
          Console.log(
            "waitForDriverActivation resetting driver",
            "currentOutputId=\(String(describing: currentOutputId))",
            "driverId=\(String(describing: driverId))",
            "hidden=\(Driver.hidden)"
          )

          if Driver.hidden == false {
            Driver.shown = false
          }

          Async.delay(200) {
            Driver.show {
              if let driverDevice = Driver.device {
                AudioDevice.currentOutputDevice = driverDevice
                AudioDevice.currentSystemDevice = driverDevice
              }
              finishIfReady()
            }
          }
          return
        }

        Console.log(
          "waitForDriverActivation timeout",
          "currentOutputId=\(String(describing: currentOutputId))",
          "driverId=\(String(describing: driverId))",
          "hidden=\(Driver.hidden)"
        )
        completion()
        return
      }

      if Driver.hidden {
        Driver.shown = true
      }

      if let driverDevice = Driver.device {
        AudioDevice.currentOutputDevice = driverDevice
        AudioDevice.currentSystemDevice = driverDevice
      }

      Async.delay(pollMs) {
        finishIfReady()
      }
    }

    finishIfReady()
  }

  private static func getLastKnowDeviceFromStack () -> AudioDevice {
    var device: AudioDevice?
    if (lastKnownDeviceStack.count > 0) {
      device = lastKnownDeviceStack.removeLast()
    } else {
      device = selectedDevice ?? AudioDevice.builtInOutputDevice
    }
    guard device != nil, device!.id != Driver.device!.id else {
      selectedDevice = nil
      return getLastKnowDeviceFromStack()
    }

    Console.log("Last known device: \(device!.id) - \(device!.name)")
    guard let newDevice = Outputs.allowedDevices.first(where: { $0.id == device!.id || $0.name == device!.name }) else {
      Console.log("Last known device is not currently available, trying next")
      return getLastKnowDeviceFromStack()
    }

    return newDevice
  }

  private static func stabilizeInputDeviceForSelectedOutput () {
    guard
      let selectedOutput = selectedDevice,
      let currentInput = AudioDevice.defaultInputDevice()
    else {
      return
    }

    if currentInput.id == Driver.device!.id {
      return
    }

    lastKnownInputDevice = currentInput
    Storage[.lastKnownInputDeviceId] = Int(currentInput.id)

    let inputPrefix = currentInput.uid?.split(separator: ":").first
    let outputPrefix = selectedOutput.uid?.split(separator: ":").first
    let sharedBluetoothEndpoint = inputPrefix != nil && inputPrefix == outputPrefix
    let sameNamedHeadset = currentInput.name == selectedOutput.name

    if sharedBluetoothEndpoint || sameNamedHeadset {
      let fallbackInput = AudioDevice.builtInInputDevice
      if fallbackInput.id != currentInput.id {
        AudioDevice.currentInputDevice = fallbackInput
      }
    }
  }

  private static func restoreLastKnownInputDevice () {
    guard let previousInput = lastKnownInputDevice else {
      return
    }

    guard previousInput.id != Driver.device!.id else {
      lastKnownInputDevice = nil
      return
    }

    if let matchingInput = AudioDevice.allInputDevices().first(where: {
      $0.id == previousInput.id || $0.uid == previousInput.uid || $0.name == previousInput.name
    }) {
      AudioDevice.currentInputDevice = matchingInput
    }

    lastKnownInputDevice = nil
  }

  private static func matchDriverSampleRateToOutput () {
    let outputSampleRate = selectedDevice!.actualSampleRate()!
    let closestSampleRate = kEQMDeviceSupportedSampleRates.min( by: { abs($0 - outputSampleRate) < abs($1 - outputSampleRate) } )!
    Driver.device!.setNominalSampleRate(closestSampleRate)
  }
  
  private static func createAudioPipeline () {
    engine = nil
    engine = Engine()
    engineCreated.emit()
    output = nil
    output = Output(device: selectedDevice!)
    outputCreated.emit()

    selectedDeviceSampleRateChangedListener = AudioDeviceEvents.on(
      .nominalSampleRateChanged,
      onDevice: selectedDevice!,
      retain: false
    ) {
      if ignoreEvents { return }
      ignoreEvents = true
      stopRemoveEngines {
        Async.delay(1000) {
          // need a delay, because emitter should finish its work at first
          try! AudioDeviceEvents.recreateEventEmitters([.isAliveChanged, .volumeChanged, .nominalSampleRateChanged])
          setupDriverDeviceEvents()
          matchDriverSampleRateToOutput()
          createAudioPipeline()
          ignoreEvents = false
        }
      }
    }

    selectedDeviceVolumeChangedListener = AudioDeviceEvents.on(
      .volumeChanged,
      onDevice: selectedDevice!,
      retain: false
    ) {
      if ignoreEvents || ignoreVolumeEvents {
        return
      }
      if ignoreNextVolumeEvent {
        ignoreNextVolumeEvent = false
        return
      }
      let deviceVolume = selectedDevice!.virtualMasterVolume(direction: .playback)!
      let driverVolume = Driver.device!.virtualMasterVolume(direction: .playback)!
      if (deviceVolume != driverVolume) {
        ignoreVolumeEvents = true
        Driver.device!.setVirtualMasterVolume(deviceVolume, direction: .playback)
        Volume.gainChanged.emit(Double(deviceVolume))
        Async.delay (50) {
          ignoreVolumeEvents = false
        }
      }
    }
    audioPipelineIsRunning.emit()
  }

  private static func rebuildAudioPipeline () {
    guard selectedDevice != nil else {
      return setupAudio()
    }

    ignoreEvents = true
    selectedDeviceVolumeChangedListener?.isListening = false
    selectedDeviceVolumeChangedListener = nil
    selectedDeviceSampleRateChangedListener?.isListening = false
    selectedDeviceSampleRateChangedListener = nil
    output?.stop()
    engine?.stop()
    removeEngines()
    createAudioPipeline()
    ignoreEvents = false
  }
  
  private static func setupUI (_ completion: @escaping () -> Void) {
    Console.log("Setting up UI")
    ui = UI {
      setupDataBus()
      completion()
    }
  }
  
  private static func setupDataBus () {
    Console.log("Setting up Data Bus")
    dataBus = ApplicationDataBus(bridge: UI.bridge)
  }
  
  static var overrideNextVolumeEvent = false
  static func volumeChangeButtonPressed (direction: VolumeChangeDirection, quarterStep: Bool = false) {
    if ignoreEvents || engine == nil || output == nil {
      return
    }
    if direction == .UP {
      ignoreNextDriverMuteEvent = true
      Async.delay(100) {
        ignoreNextDriverMuteEvent = false
      }
    }
    let gain = output!.volume.gain
    if (gain >= 1) {
      if direction == .DOWN {
        overrideNextVolumeEvent = true
      }
      
      let steps = quarterStep ? Constants.QUARTER_VOLUME_STEPS : Constants.FULL_VOLUME_STEPS
      
      var stepIndex: Int
      
      if direction == .UP {
        stepIndex = steps.index(where: { $0 > gain }) ?? steps.count - 1
      } else {
        stepIndex = steps.index(where: { $0 >= gain }) ?? 0
        stepIndex -= 1
        if (stepIndex < 0) {
          stepIndex = 0
        }
      }
      
      var newGain = steps[stepIndex]
      
      if (newGain <= 1) {
        Async.delay(100) {
          Driver.device!.setVirtualMasterVolume(Float(newGain), direction: .playback)
        }
      } else {
        if (!Application.store.state.volume.boostEnabled) {
          newGain = 1
        }
      }
      Application.dispatchAction(VolumeAction.setGain(newGain, false))
    }
  }
  
  static func muteButtonPressed () {
    ignoreNextDriverMuteEvent = false
  }
  
  private static func switchBackToLastKnownDevice () {
    // If the active equalizer global gain hass been lowered we need to equalize the volume to avoid blowing people ears out
    let device = getLastKnowDeviceFromStack()

    let globalGain = ({ () -> Double in
      let equalizersState = store.state.effects.equalizers
      let eqType = equalizersState.type

      switch eqType {
      case .basic:
        if let preset = BasicEqualizer.getPreset(id: equalizersState.basic.selectedPresetId) {
          if preset.peakLimiter {
            let gains = preset.gains
            let maxGain = [ gains.bass, gains.mid, gains.treble ].max()!
            return -maxGain
          }
        }
      case .advanced:
        if let preset = AdvancedEqualizer.getPreset(id: equalizersState.advanced.selectedPresetId) {
          return preset.gains.global
        }
      }
      return 0
    })()


    if (globalGain < 0) {
      if (device.canSetVirtualMasterVolume(direction: .playback)) {
        var decibels =
          device.volumeInDecibels(channel: 0, direction: .playback)
          ?? device.volumeInDecibels(channel: 1, direction: .playback)
          ?? 0.5
        decibels = decibels + Float(globalGain)
        let newVolume = device.decibelsToScalar(volume: decibels, channel: 0, direction: .playback) ?? device.decibelsToScalar(volume: decibels, channel: 1, direction: .playback) ?? 0.1
        device.setVirtualMasterVolume(newVolume, direction: .playback)
      } else if (device.canSetVolume(channel: 1, direction: .playback)) {
        var decibels = device.volumeInDecibels(channel: 1, direction: .playback)!
        decibels = decibels + Float(globalGain)
        for channel in 1...device.channels(direction: .playback) {
          device.setVolume(device.decibelsToScalar(volume: decibels, channel: channel, direction: .playback)!, channel: channel, direction: .playback)
        }
      }
    }

    Driver.name = ""
    AudioDevice.currentOutputDevice = device
    AudioDevice.currentSystemDevice = device
    restoreLastKnownInputDevice()
  }

  static func stopEngines (_ completion: @escaping () -> Void) {
    DispatchQueue.main.async {
      output?.stop()
      engine?.stop()
      completion()
    }
  }

  static func removeEngines () {
    output = nil
    engine = nil
  }

  static func stopRemoveEngines (_ completion: @escaping () -> Void) {
    stopEngines {
      removeEngines()
      completion()
    }
  }

  static func stopSave (_ completion: @escaping () -> Void) {
    Console.log("stopSave begin")
    Storage.synchronize()
    stopListeners()
    stopRemoveEngines {
      switchBackToLastKnownDevice()
      Console.log("stopSave complete")
      completion()
    }
  }

  static func handleSleep () {
    ignoreEvents = true
    if enabled {
      stopSave {}
    }
  }

  static func handleWakeUp () {
    // Wait for devices to initialize, not sure what delay is appropriate
    Async.delay(1000) {
      if !enabled { return }
      if lastKnownDeviceStack.count == 0 { return setupAudio() }
      let lastDevice = lastKnownDeviceStack.last
      var tries = 0
      let maxTries = 5

      func checkLastKnownDeviceActive () {
        tries += 1
        if tries <= maxTries {
          let newDevice = Outputs.allowedDevices.first(where: { $0.id == lastDevice!.id || $0.name == lastDevice!.name })
          if newDevice != nil && newDevice!.isAlive() && newDevice!.nominalSampleRate() != nil {
            setupAudio()
          } else {
            Async.delay(1000) {
              checkLastKnownDeviceActive()
            }
          }
        } else {
          // Tried as much as we could, continue with something else
          setupAudio()
        }
      }

      checkLastKnownDeviceActive()
    }
  }
  
  static func quit () {
    NSApp.terminate(nil)
  }
  
  static func handleTermination (_ completion: (() -> Void)? = nil) {
    Console.log("handleTermination begin")
    stopSave {
      Driver.hidden = true
      Console.log("handleTermination complete")
      if completion != nil {
        completion!()
      }
    }
  }
  
  static func restart () {
    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [path]
    task.launch()
    quit()
  }
  
  static func restartMac () {
    Script.apple("restart_mac")
  }
  
  static func checkForUpdates () {
    guard Settings.updatesFeedUrl != nil else {
      NSWorkspace.shared.open(Constants.RELEASES_URL)
      return
    }

    updater.checkForUpdates(nil)
  }
  
  static func uninstall () {
    // TODO: Implement uninstaller
    Console.log("// TODO: Download Uninstaller")
  }
  
  static func stopListeners () {
    AudioDeviceEvents.stop()
    selectedDeviceIsAliveListener?.isListening = false
    selectedDeviceIsAliveListener = nil
    
    audioPipelineIsRunningListener?.isListening = false
    audioPipelineIsRunningListener = nil
    
    selectedDeviceVolumeChangedListener?.isListening = false
    selectedDeviceVolumeChangedListener = nil
    
    selectedDeviceSampleRateChangedListener?.isListening = false
    selectedDeviceSampleRateChangedListener = nil
  }
  
  static var version: String {
    return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
  }

  static var buildNumber: String {
    return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
  }
  
  static func newState (_ state: ApplicationState) {
    if state.enabled != enabled {
      Console.log("Application.newState enabled changed", "old=\(enabled)", "new=\(state.enabled)")
    }
    if state.enabled != enabled {
      enabled = state.enabled
    }

    let spatialAudioEnabled = state.ui.settings["spatialAudioEnabled"].bool ?? false
    if output?.spatialAudioEnabled != spatialAudioEnabled {
      output?.setSpatialAudioEnabled(spatialAudioEnabled)
    }
  }
  
  static var supportPath: URL {
    //Create App directory if not exists:
    let fileManager = FileManager()
    let urlPaths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    
    let appDirectory = urlPaths.first!.appendingPathComponent(Bundle.main.bundleIdentifier! ,isDirectory: true)
    var objCTrue: ObjCBool = true
    let path = appDirectory.path
    if !fileManager.fileExists(atPath: path, isDirectory: &objCTrue) {
      try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
    return appDirectory
  }
  
  static private let dispatchActionQueue = DispatchQueue(label: "dispatchActionQueue", qos: .userInitiated)
  // Custom dispatch function. Need to execute some dispatches on the main thread
  static func dispatchAction(_ action: Action, onMainThread: Bool = true) {
    Console.log("dispatchAction", "\(type(of: action))", "onMainThread=\(onMainThread)")
    if (onMainThread) {
      if Thread.isMainThread {
        store.dispatch(action)
      } else {
        DispatchQueue.main.async {
          store.dispatch(action)
        }
      }
    } else {
      dispatchActionQueue.async {
        store.dispatch(action)
      }
    }
  }
}
