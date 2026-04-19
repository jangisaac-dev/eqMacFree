//
//  Output.swift
//  eqMac
//
//  Created by Roman Kisil on 05/11/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Foundation
import AMCoreAudio
import SwiftyUserDefaults
import EmitterKit
import AVFoundation
import AudioToolbox
import Shared

private struct SpatialAudioConfiguration {
  let leftPosition: AVAudio3DPoint
  let rightPosition: AVAudio3DPoint
  let dryMix: Float
  let wetMix: Float
  let reverbBlend: Float
  let crossfeed: Float
}

private enum SpatialSourceKind {
  case left
  case right
}

private struct SpatialRenderCache {
  var frameCount: AVAudioFrameCount = 0
  var left: [Float] = []
  var right: [Float] = []
  var pendingKinds: Set<SpatialSourceKind> = []
}

class Output {
  var device: AudioDevice
  let volume: Volume
  var outputEngine = AVAudioEngine()
  var player = AVAudioPlayerNode()
  var varispeed = AVAudioUnitVarispeed()
  var dryMixer = AVAudioMixerNode()
  var wetMixer = AVAudioMixerNode()
  var spatialEnvironment = AVAudioEnvironmentNode()
  var spatialLeftSource: AVAudioSourceNode?
  var spatialRightSource: AVAudioSourceNode?
  fileprivate var currentSpatialConfiguration: SpatialAudioConfiguration?
  private let spatialRenderLock = NSLock()
  private var spatialRenderCache = SpatialRenderCache()
  private var spatialSampleTime: Double = -1
  let deviceChanged = EmitterKit.Event<AudioDevice>()
  
  var lastSampleTime: Double = -1
  var safetyOffset: Double = 0
  var sampleOffset: Double = 0

  var integral: Double = 0
  var prevError: Double = 0
  var initialVarispeedRate: Float
  var lowestVarispeedRate: Float
  var highestVarispeedRate: Float

  var spatialAudioEnabled: Bool {
    return Application.store.state.settings.spatialAudioEnabled
  }

  var spatialAudioPreset: SpatialAudioPreset {
    return Application.store.state.settings.spatialAudioPreset
  }

  init(device: AudioDevice) {
    Console.log("Creating Output for Device: " + device.name)
    self.device = device
    self.volume = Volume()

    outputEngine.setOutputDevice(device)
    
    let format = AVAudioFormat.init(
      standardFormatWithSampleRate: device.nominalSampleRate()!,
      channels: 2
    )!

    varispeed.rate = Float(Driver.device!.actualSampleRate()! / device.actualSampleRate()!)
    initialVarispeedRate = varispeed.rate
    // Clamp new Rate to not exceed 0.2% in either direction
    let bounds = 0.002
    lowestVarispeedRate = initialVarispeedRate * Float(1.0 - bounds)
    highestVarispeedRate = initialVarispeedRate * Float(1.0 + bounds)
    Console.log("Varispeed Rate: \(varispeed.rate), Lowest: \(lowestVarispeedRate), Highest: \(highestVarispeedRate)")

    outputEngine.attach(player)
    outputEngine.attach(varispeed)
    outputEngine.attach(dryMixer)
    outputEngine.attach(wetMixer)
    outputEngine.attach(spatialEnvironment)
    outputEngine.attach(volume.mixer)
    outputEngine.connect(player, to: varispeed, format: format)
    outputEngine.connect(varispeed, to: dryMixer, format: format)
    outputEngine.connect(dryMixer, to: volume.mixer, format: format)

    let monoFormat = AVAudioFormat(
      standardFormatWithSampleRate: device.nominalSampleRate()!,
      channels: 1
    )!

    let spatialLeftSource = makeSpatialSourceNode(format: monoFormat, kind: .left)
    let spatialRightSource = makeSpatialSourceNode(format: monoFormat, kind: .right)
    self.spatialLeftSource = spatialLeftSource
    self.spatialRightSource = spatialRightSource
    outputEngine.attach(spatialLeftSource)
    outputEngine.attach(spatialRightSource)
    outputEngine.connect(spatialLeftSource, to: spatialEnvironment, format: monoFormat)
    outputEngine.connect(spatialRightSource, to: spatialEnvironment, format: monoFormat)
    outputEngine.connect(spatialEnvironment, to: wetMixer, format: format)
    outputEngine.connect(wetMixer, to: volume.mixer, format: format)
    updateSpatialAudioState(enabled: spatialAudioEnabled, preset: spatialAudioPreset, logChange: false)
    
    outputEngine.connect(volume.mixer, to: outputEngine.mainMixerNode, format: format)
    
    self.setupCallback()
    
    Async.delay(200) { [weak self] in
      self?.start()
      self?.startComputeVarispeedRate()
    }
  }

  private func spatialAudioConfiguration(for preset: SpatialAudioPreset) -> SpatialAudioConfiguration {
    switch preset {
    case .cinema:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -3.2, y: 0.12, z: -2.8),
        rightPosition: AVAudio3DPoint(x: 3.2, y: 0.12, z: -2.8),
        dryMix: 0.72,
        wetMix: 0.88,
        reverbBlend: 18,
        crossfeed: 0.0
      )
    case .music:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -1.55, y: 0.05, z: -1.65),
        rightPosition: AVAudio3DPoint(x: 1.55, y: 0.05, z: -1.65),
        dryMix: 0.84,
        wetMix: 0.48,
        reverbBlend: 8,
        crossfeed: 0.08
      )
    case .voice:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -0.85, y: 0.02, z: -1.0),
        rightPosition: AVAudio3DPoint(x: 0.85, y: 0.02, z: -1.0),
        dryMix: 0.92,
        wetMix: 0.28,
        reverbBlend: 3,
        crossfeed: 0.18
      )
    case .studio:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -1.1, y: 0.03, z: -1.15),
        rightPosition: AVAudio3DPoint(x: 1.1, y: 0.03, z: -1.15),
        dryMix: 0.96,
        wetMix: 0.20,
        reverbBlend: 2,
        crossfeed: 0.12
      )
    case .live:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -2.2, y: 0.18, z: -2.2),
        rightPosition: AVAudio3DPoint(x: 2.2, y: 0.18, z: -2.2),
        dryMix: 0.78,
        wetMix: 0.64,
        reverbBlend: 14,
        crossfeed: 0.05
      )
    case .gaming:
      return SpatialAudioConfiguration(
        leftPosition: AVAudio3DPoint(x: -1.85, y: 0.0, z: -1.45),
        rightPosition: AVAudio3DPoint(x: 1.85, y: 0.0, z: -1.45),
        dryMix: 0.82,
        wetMix: 0.56,
        reverbBlend: 6,
        crossfeed: 0.02
      )
    }
  }

  private func applySpatialAudioPreset (
    _ configuration: SpatialAudioConfiguration,
    leftSource: AVAudioMixing,
    rightSource: AVAudioMixing
  ) {
    currentSpatialConfiguration = configuration
    leftSource.renderingAlgorithm = .HRTF
    leftSource.pointSourceInHeadMode = .mono
    leftSource.position = configuration.leftPosition
    leftSource.reverbBlend = configuration.reverbBlend

    rightSource.renderingAlgorithm = .HRTF
    rightSource.pointSourceInHeadMode = .mono
    rightSource.position = configuration.rightPosition
    rightSource.reverbBlend = configuration.reverbBlend

    spatialEnvironment.reverbParameters.enable = configuration.reverbBlend > 0
    spatialEnvironment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
  }

  func updateSpatialAudioState (enabled: Bool, preset: SpatialAudioPreset, logChange: Bool = true) {
    let configuration = spatialAudioConfiguration(for: preset)
    if let spatialLeftSource, let spatialRightSource {
      applySpatialAudioPreset(configuration, leftSource: spatialLeftSource, rightSource: spatialRightSource)
    } else {
      currentSpatialConfiguration = configuration
    }

    if enabled {
      dryMixer.outputVolume = configuration.dryMix
      wetMixer.outputVolume = configuration.wetMix
      if logChange {
        Console.log("Spatial Audio updated in-place: enabled preset=\(preset.rawValue)")
      }
    } else {
      dryMixer.outputVolume = 1
      wetMixer.outputVolume = 0
      if logChange {
        Console.log("Spatial Audio updated in-place: disabled")
      }
    }
  }

  private func makeSpatialSourceNode (format: AVAudioFormat, kind: SpatialSourceKind) -> AVAudioSourceNode {
    return AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
      let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)

      guard let output = Application.output,
            let engine = Application.engine,
            engine.engine.isRunning,
            engine.lastSampleTime != -1 else {
        makeBufferSilent(abl)
        return noErr
      }

      output.spatialRenderLock.lock()
      defer { output.spatialRenderLock.unlock() }

      if output.spatialSampleTime == -1 {
        output.spatialSampleTime = output.lastSampleTime == -1
          ? engine.lastSampleTime
          : output.lastSampleTime
      }

      let shouldRefreshCache =
        output.spatialRenderCache.frameCount != frameCount ||
        output.spatialRenderCache.pendingKinds.isEmpty ||
        !output.spatialRenderCache.pendingKinds.contains(kind)

      if shouldRefreshCache {
        let from = Int64(output.spatialSampleTime + output.sampleOffset - output.safetyOffset)
        let to = from + Int64(frameCount)

        let stereoList = AudioBufferList.allocate(maximumBuffers: 2)
        defer {
          for index in 0..<Int(stereoList.unsafeMutablePointer.pointee.mNumberBuffers) {
            free(stereoList[index].mData)
          }

          stereoList.unsafeMutablePointer.deallocate()
        }

        stereoList.unsafeMutablePointer.pointee.mNumberBuffers = 2

        for index in 0..<2 {
          stereoList[index] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: frameCount * UInt32(MemoryLayout<Float>.size),
            mData: calloc(Int(frameCount), MemoryLayout<Float>.size)
          )
        }

        let err = engine.buffer.read(into: stereoList.unsafeMutablePointer, from: from, to: to)

        if err != .noError {
          makeBufferSilent(abl)
          Console.log("Spatial Audio read error: \(err)")
          output.resetOffsets()
          output.spatialRenderCache.pendingKinds = []
          return noErr
        }

        let left = stereoList[0].mData!.assumingMemoryBound(to: Float.self)
        let right = stereoList[1].mData!.assumingMemoryBound(to: Float.self)

        output.spatialRenderCache.frameCount = frameCount
        output.spatialRenderCache.left = Array(UnsafeBufferPointer(start: left, count: Int(frameCount)))
        output.spatialRenderCache.right = Array(UnsafeBufferPointer(start: right, count: Int(frameCount)))
        output.spatialRenderCache.pendingKinds = [ .left, .right ]
        output.spatialSampleTime += Double(frameCount)
      }

      let configuration = output.currentSpatialConfiguration ?? output.spatialAudioConfiguration(for: output.spatialAudioPreset)
      let channelGain: (Float, Float) = {
        switch kind {
        case .left:
          return (1, configuration.crossfeed)
        case .right:
          return (configuration.crossfeed, 1)
        }
      }()

      for buffer in abl {
        let mono = buffer.mData!.assumingMemoryBound(to: Float.self)

        for frame in 0..<Int(frameCount) {
          mono[frame] =
            (output.spatialRenderCache.left[frame] * channelGain.0) +
            (output.spatialRenderCache.right[frame] * channelGain.1)
        }
      }

      output.spatialRenderCache.pendingKinds.remove(kind)
      return noErr
    }
  }
  
  private func setupCallback () {
    var callbackStruct = AURenderCallbackStruct(
      inputProc: callback,
      inputProcRefCon: nil
    )
    
    AudioUnitSetProperty(
      varispeed.audioUnit,
      kAudioUnitProperty_SetRenderCallback,
      kAudioUnitScope_Input, 0,
      &callbackStruct,
      UInt32(MemoryLayout<AURenderCallbackStruct>.size)
    )
  }

  let callback: AURenderCallback = {
    (inRefCon: UnsafeMutableRawPointer,
     ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
     inTimeStamp:  UnsafePointer<AudioTimeStamp>,
     inBusNumber: UInt32,
     inNumberFrames: UInt32,
     ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
    let abl = UnsafeMutableAudioBufferListPointer(ioData)!

    // Nothing to work with...
    if (Application.output == nil
          || Application.engine == nil
          || !Application.engine!.engine.isRunning
          || Application.engine!.lastSampleTime == -1
    ) {
      makeBufferSilent(abl)
      return noErr
    }

    let sampleTime = inTimeStamp.pointee.mSampleTime

    // If first run, compute offset
    if (Application.output!.lastSampleTime == -1) {
      Application.output!.lastSampleTime = sampleTime
      Application.output!.computeOffset()
      makeBufferSilent(abl)
      return noErr
    } else {
      Application.output!.lastSampleTime = sampleTime
    }

    let from = Int64(sampleTime + Application.output!.sampleOffset - Application.output!.safetyOffset)
    let to = from + Int64(inNumberFrames)
    let err = Application.engine!.buffer.read(into: ioData!, from: from, to: to)

    if err != .noError {
      makeBufferSilent(abl)
      Console.log("ERROR: \(err)")
      Application.output!.resetOffsets()
      return noErr
    }
    
    return noErr
  }
  
  private func start () {
    outputEngine.prepare()
    Console.log("Starting Output Engine")
    Console.log(outputEngine)
    try! outputEngine.start()
    Console.log("Output Engine started")
  }
  
  private func computeOffset() {
    let inputDevice = Driver.device!
    let inputOffset = inputDevice.safetyOffset(direction: .recording)
    let inputBuffer = inputDevice.bufferFrameSize(direction: .recording)
    let outputOffset = device.safetyOffset(direction: .playback)
    let outputBuffer = device.bufferFrameSize(direction: .playback)
    safetyOffset = Double(inputOffset! + outputOffset! + inputBuffer + outputBuffer)// + pow(2, 12)
    sampleOffset = Application.engine!.lastSampleTime - lastSampleTime
    Console.log("Last Input Time: ", Application.engine!.lastSampleTime)
    Console.log("Last Output Time: ", lastSampleTime)
    Console.log("Safety Offset: ", safetyOffset)
    Console.log("Sample Offset: ", sampleOffset)
  }

  // PID Controller to adjust Varispeed rate so we never go beyond Safety Offset
  private let computeVarispeedCyclesPerSecond = 10
  private func startComputeVarispeedRate () {
    stopComputeVarispeedRate()
    computeVarispeedRateTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
    computeVarispeedRateTimer!.setEventHandler { [weak self] in
      self?.computeVarispeedRate()
    }
    computeVarispeedRateTimer!.schedule(deadline: .now(), repeating: .milliseconds(1000 / computeVarispeedCyclesPerSecond))
    computeVarispeedRateTimer!.resume()
  }
  private func stopComputeVarispeedRate () {
    computeVarispeedRateTimer?.cancel()
  }
  private var computeVarispeedRateTimer: DispatchSourceTimer?
  private var safetyOffsetsHistory: [Double] = []
  private func computeVarispeedRate () {
    //    let benchmark = Benchmark()
    if Application.engine == nil || lastSampleTime == -1 { return }

    // Calculate the Latest Safety offset and filter it by averaging with last second of data
    let lastSafetyOffset = Application.engine!.lastSampleTime - (lastSampleTime + sampleOffset - safetyOffset)
    safetyOffsetsHistory.insert(lastSafetyOffset, at: 0)
    let historyMaxLength = computeVarispeedCyclesPerSecond
    if (safetyOffsetsHistory.count > historyMaxLength) {
      safetyOffsetsHistory.removeLast(safetyOffsetsHistory.count - historyMaxLength)
    }
    let safetyOffsetAverage = safetyOffsetsHistory.reduce(0, +) / Double(safetyOffsetsHistory.count)

    // Calculate Imperfection/Error
    let errorRatio = safetyOffset / safetyOffsetAverage
    let error = 1.0 - errorRatio

    // PID Controls
    let Kp = 0.0001
    let Ki = 0.0
    let Kd = 0.0001

    let Dt = 1.0 / Double(computeVarispeedCyclesPerSecond)

    // Proportional
    let p = Kp * error

    // Integral
    integral += error * Dt
    let i = Ki * integral

    // Derivative
    let der = (error - prevError) / Dt
    let d = Kd * der

    prevError = error

    let change = Float(p + i + d)
    var newRate = varispeed.rate + change

    if newRate < lowestVarispeedRate {
      newRate = lowestVarispeedRate
    } else if newRate > highestVarispeedRate {
      newRate = highestVarispeedRate
    }

    varispeed.rate = newRate
    //        Console.log("Took \(benchmark.end())ms to recalculate Varispeed rate: \(varispeed.rate)")
    //    print("\n\nInput Last: \(engine.lastSampleTime)\nOutput Last: \(lastSampleTime)\nSafety Offset: \(safetyOffset)\nLast Safety Offset: \(lastSafetyOffset)\nSafety Offset Avg: \(safetyOffsetAverage)\nError: \(String(format: "%.3f", error * 100))%\nDt: \(Dt)\nIntegral: \(integral)\nPID: \(p), \(i), \(d)\nRate Change: \(change)\nNew Varispeed Rate: \(varispeed.rate)\n")
  }

  func resetOffsets () {
    integral = 0
    varispeed.rate = initialVarispeedRate
    spatialRenderLock.lock()
    spatialSampleTime = -1
    spatialRenderCache = SpatialRenderCache()
    spatialRenderLock.unlock()
    computeOffset()
  }
  
  func stop () {
    outputEngine.stop()
  }
}
