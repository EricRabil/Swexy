//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 7/19/22.
//

import Foundation

@propertyWrapper
public class Atomic<T> {
    private var _wrappedValue: T
    
    private let semaphore = DispatchSemaphore(value: 1)
    public var wrappedValue: T {
        _read {
            semaphore.wait()
            yield _wrappedValue
            semaphore.signal()
        }
        _modify {
            semaphore.wait()
            yield &_wrappedValue
            semaphore.signal()
        }
    }
    
    public init(wrappedValue: T) {
        _wrappedValue = wrappedValue
    }
}
