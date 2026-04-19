//
//  SettingsState.swift
//  eqMac
//
//  Created by Romans Kisils on 15/07/2019.
//  Copyright © 2019 Romans Kisils. All rights reserved.
//

import Foundation

import SwiftyUserDefaults
import ReSwift
import BetterCodable

enum SpatialAudioPreset: String, Codable, CaseIterable {
  case cinema = "cinema"
  case music = "music"
  case voice = "voice"
  case studio = "studio"
  case live = "live"
  case gaming = "gaming"
}

struct SettingsState: State {
  var iconMode: IconMode = .both
  @DefaultFalse var doCollectCrashReports = false
  @DefaultFalse var doAutoCheckUpdates = false
  @DefaultFalse var doOTAUpdates = false
  @DefaultFalse var doBetaUpdates = false
  @DefaultFalse var spatialAudioEnabled = false
  var spatialAudioPreset: SpatialAudioPreset = .music
}

enum SettingsAction: Action {
  case setIconMode(IconMode)
  case setDoCollectCrashReports(Bool)
  case setDoAutoCheckUpdates(Bool)
  case setDoOTAUpdates(Bool)
  case setDoBetaUpdates(Bool)
  case setSpatialAudioEnabled(Bool)
  case setSpatialAudioPreset(SpatialAudioPreset)
}

func SettingsStateReducer(action: Action, state: SettingsState?) -> SettingsState {
  var state = state ?? SettingsState()
  switch action as? SettingsAction {
  case .setIconMode(let iconMode)?:
    state.iconMode = iconMode
  case .setDoCollectCrashReports(let doCollect)?:
    state.doCollectCrashReports = doCollect
  case .setDoAutoCheckUpdates(let doAutoCheckUpdates)?:
    state.doAutoCheckUpdates = doAutoCheckUpdates
  case .setDoOTAUpdates(let doOTAUpdates)?:
    state.doOTAUpdates = doOTAUpdates
  case .setDoBetaUpdates(let doBetaUpdates)?:
    state.doBetaUpdates = doBetaUpdates
  case .setSpatialAudioEnabled(let spatialAudioEnabled)?:
    state.spatialAudioEnabled = spatialAudioEnabled
  case .setSpatialAudioPreset(let spatialAudioPreset)?:
    state.spatialAudioPreset = spatialAudioPreset
  case .none:
    break
  }
  
  return state
}
