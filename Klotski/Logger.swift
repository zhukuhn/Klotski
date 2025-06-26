//
//  Logger.swift
//  Klotski
//
//  Created by zhukun on 2025/6/27.
//
import Foundation

/// A custom logger that only prints messages in DEBUG builds.
///
/// - Parameters:
///   - message: The message to be logged. Can be any type.
///   - file: The name of the file in which this function was called. Defaults to #file.
///   - function: The name of the function in which this function was called. Defaults to #function.
///   - line: The line number on which this function was called. Defaults to #line.
public func debugLog(_ message: Any, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    // The #if DEBUG directive ensures this code is only compiled for Debug builds.
    // It will be completely removed from Release builds submitted to the App Store.
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) -> \(message)")
    #endif
}
