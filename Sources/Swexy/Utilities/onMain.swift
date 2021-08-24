//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/24/21.
//

import Foundation

public func onMain<T>(_ cb: @autoclosure () throws -> T) rethrows -> T {
    if Thread.isMainThread { return try cb() }
    else { return try DispatchQueue.main.sync(execute: cb) }
}
