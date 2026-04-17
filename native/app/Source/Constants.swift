//
//  Constants.swift
//  eqMac
//
//  Created by Roman Kisil on 22/01/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Foundation
import AMCoreAudio
import Version

struct Constants {
  static let REPO_OWNER = "jangisaac-dev"
  static let REPO_NAME = "eqMacFree"
  static let RELEASE_TAG_PREFIX = "eqmacfree-v"
  static let REPO_URL = URL(string: "https://github.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)")!
  static let README_URL = URL(string: "https://github.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)#readme")!
  static let ISSUES_URL = URL(string: "https://github.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)/issues")!
  static let NEW_ISSUE_URL = URL(string: "https://github.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)/issues/new/choose")!
  static let RELEASES_URL = URL(string: "https://github.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)/releases")!
  static let RAW_CONTENT_URL = URL(string: "https://raw.githubusercontent.com/\(Constants.REPO_OWNER)/\(Constants.REPO_NAME)/main")!
  static let REMOTE_SERVICES_ENABLED = false
  static let TELEMETRY_ENABLED = false
  static let CRASH_REPORTING_ENABLED = false
  
  #if DEBUG
//  static let UI_ENDPOINT_URL = URL(string: "http://www.eqmac.local:8080")!
  static let UI_ENDPOINT_URL = URL(string: "http://localhost:8080")!

  static let DEBUG = true
  #else
  static let DEBUG = false
  static let UI_ENDPOINT_URL = URL(string: "http://localhost:8080")!
  #endif
  
  static let SENTRY_ENDPOINT: String? = nil
  static let DOMAIN = "github.com"
  static let WEBSITE_URL = REPO_URL
  static let FAQ_URL = README_URL
  static let BUG_REPORT_URL = NEW_ISSUE_URL
  static let DRIVER_DEVICE_UID = "EQMDevice"
  static let DRIVER_MINIMUM_VERSION = Version(tolerant: "1.0.0")!
  static let LEGACY_DRIVER_UIDS = ["EQMAC2.1_DRIVER_ENGINE", "EQMAC2_DRIVER_ENGINE"]
  static let TOKEN_STORAGE_KEY = "eqMac Server Tokens"
  static let UI_SERVER_PREFERRED_PORT: UInt = 37628
  static let HTTP_SERVER_PREFERRED_PORT: UInt = 37624
  static let SOCKET_SERVER_PREFERRED_PORT: UInt = 37629
  static let FULL_VOLUME_STEP = 1.0 / 16
  static let QUARTER_VOLUME_STEP = FULL_VOLUME_STEP / 4
  static let FULL_VOLUME_STEPS: [Double] = Array(stride(from: 0.0, through: 2.0, by: FULL_VOLUME_STEP))
  static let QUARTER_VOLUME_STEPS: [Double] = Array(stride(from: 0.0, through: 2.0, by: QUARTER_VOLUME_STEP))
  
  static let TRANSITION_DURATION: UInt = 500
  static let TRANSITION_FPS: Double = 30
  static let TRANSITION_FRAME_DURATION: Double = 1000 / TRANSITION_FPS
  static let TRANSITION_FRAME_COUNT = UInt(round(TRANSITION_FPS * (Double(TRANSITION_DURATION) / 1000)))
  static let OPEN_SOURCE = true
  static let UPDATES_FEED = RAW_CONTENT_URL.appendingPathComponent("docs/appcast/stable.xml")
  static let BETA_UPDATES_FEED = RAW_CONTENT_URL.appendingPathComponent("docs/appcast/beta.xml")
  static let OPEN_URL_TRUSTED_DOMAINS: [String] = ["github.com"]
  static let TRUSTED_URL_PREFIXES: [String] = [
    "https://github.com/jangisaac-dev/eqMacFree",
    "https://github.com/jaakkopasanen/AutoEq"
  ]
}
