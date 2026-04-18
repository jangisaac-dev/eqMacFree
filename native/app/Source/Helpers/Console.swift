//
//  Console.swift
//  eqMac
//
//  Created by Roman Kisil on 29/04/2018.
//  Copyright © 2018 Roman Kisil. All rights reserved.
//

import Foundation

class Console {
  private static let writeQueue = DispatchQueue(label: "dev.jangisaac.eqmacfree.console-log", qos: .utility)
  private static let maxLogSizeBytes = 5 * 1024 * 1024

  private static var logFileURL: URL {
    let logsDirectory = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Logs/eqMacFree", isDirectory: true)

    if !FileManager.default.fileExists(atPath: logsDirectory.path) {
      try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
    }

    return logsDirectory.appendingPathComponent("eqMacFree.log", isDirectory: false)
  }

  private static func rotateIfNeeded(fileURL: URL) {
    guard
      let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
      let fileSize = attributes[.size] as? NSNumber,
      fileSize.intValue >= maxLogSizeBytes
    else {
      return
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    let archivedURL = fileURL.deletingPathExtension().appendingPathExtension(formatter.string(from: Date()) + ".log")
    try? FileManager.default.removeItem(at: archivedURL)
    try? FileManager.default.moveItem(at: fileURL, to: archivedURL)
  }

  private static func appendToFile(_ line: String) {
    writeQueue.async {
      let fileURL = logFileURL
      rotateIfNeeded(fileURL: fileURL)

      if !FileManager.default.fileExists(atPath: fileURL.path) {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
      }

      guard let data = (line + "\n").data(using: .utf8) else {
        return
      }

      do {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
          handle.closeFile()
        }
        handle.seekToEndOfFile()
        handle.write(data)
      } catch {
        return
      }
    }
  }

  static func log (_ somethings: Any..., fileAbsolutePath: String = #file, line: Int = #line) {
    let file = fileAbsolutePath[fileAbsolutePath.range(of: "/app/")!.upperBound...]
    let dataFormatter = DateFormatter()
    dataFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
    let message = "\(dataFormatter.string(from: Date())) eqMac (\(file):\(line)) \(somethings.map { ($0 as AnyObject).debugDescription }.joined(separator: " "))"
    print(message)
    appendToFile(message)
  }
}
