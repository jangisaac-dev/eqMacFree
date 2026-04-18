//
//  EQMClients.swift
//  eqMac
//
//  Created by Nodeful on 29/08/2021.
//  Copyright © 2021 Bitgapp. All rights reserved.
//

import Foundation
import CoreAudio.AudioServerPlugIn
import Shared
import Darwin

class EQMClients {
  private static let mutex = Mutex()
  static var clients: [UInt32: EQMClient] = [:]
  private static let pidPathBufferSize = Int(MAXPATHLEN * 4)

  private static func bundleIdentifier(for processId: pid_t) -> String? {
    guard processId > 0 else {
      return nil
    }

    var pathBuffer = [CChar](repeating: 0, count: pidPathBufferSize)
    let pathLength = proc_pidpath(processId, &pathBuffer, UInt32(pathBuffer.count))
    guard pathLength > 0 else {
      return nil
    }

    let executableURL = URL(fileURLWithPath: String(cString: pathBuffer))
    let bundleURL = executableURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    guard bundleURL.pathExtension == "app" else {
      return nil
    }

    return Bundle(url: bundleURL)?.bundleIdentifier
  }

  private static func hasRunningProcess(matchingBundleIdentifier targetBundleIdentifier: String) -> Bool {
    let maxCount = proc_listallpids(nil, 0)
    guard maxCount > 0 else {
      return false
    }

    let pidSize = MemoryLayout<pid_t>.size
    let bufferSize = Int(maxCount) * pidSize
    let pidBuffer = UnsafeMutablePointer<pid_t>.allocate(capacity: Int(maxCount))
    defer { pidBuffer.deallocate() }

    let actualBytes = proc_listallpids(pidBuffer, Int32(bufferSize))
    guard actualBytes > 0 else {
      return false
    }

    let count = Int(actualBytes) / pidSize
    for index in 0..<count {
      if bundleIdentifier(for: pidBuffer[index]) == targetBundleIdentifier {
        return true
      }
    }

    return false
  }

  static func add (_ client: EQMClient) {
    mutex.lock()
    clients[client.clientId] = client
    mutex.unlock()
  }

  static func remove (_ client: EQMClient) {
    mutex.lock()
    clients.removeValue(forKey: client.clientId)
    mutex.unlock()
  }

  static func get (clientId: UInt32) -> EQMClient? {
    mutex.lock()
    let client = clients[clientId]
    mutex.unlock()
    return client
  }

  static func get (processId: pid_t) -> EQMClient? {
    mutex.lock()
    let client = clients.values.first { $0.processId == processId }
    mutex.unlock()
    if let client = client {
      return client
    }

    guard let bundleIdentifier = bundleIdentifier(for: processId) else {
      return nil
    }

    return EQMClient(clientId: 0, processId: processId, bundleId: bundleIdentifier)
  }

  static func get (bundleId: String) -> [EQMClient] {
    mutex.lock()
    let matchingClients = clients.values.filter { client in
      return client.bundleId == bundleId
    }
    mutex.unlock()
    return matchingClients
  }

  static func get (client: EQMClient) -> EQMClient? {
    if let byClient = get(clientId: client.clientId) {
      return byClient
    }

    if let byProcessId = get(processId: client.processId) {
      return byProcessId
    }

    if let bundleId = client.bundleId {
      let bundles = get(bundleId: bundleId)
      return bundles[0]
    }

    return nil
  }

  static var isAppClientPresent: Bool {
    if Array(clients.values).contains(where: { $0.bundleId == APP_BUNDLE_ID }) {
      return true
    }

    return hasRunningProcess(matchingBundleIdentifier: APP_BUNDLE_ID)
  }
}
