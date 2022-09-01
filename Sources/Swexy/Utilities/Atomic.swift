//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 7/19/22.
//

import Foundation

@propertyWrapper
public enum Atomic<T> {
    case atomic(innerValue: T, semaphore: DispatchSemaphore)
    
    @usableFromInline typealias MemoryLayout = (T, DispatchSemaphore)
    
    @usableFromInline var memoryLayout: MemoryLayout {
        @_transparent get {
            unsafeBitCast(self, to: MemoryLayout.self)
        }
    }
    
    @_transparent @usableFromInline var semaphore: DispatchSemaphore {
        memoryLayout.1
    }
    
    @usableFromInline var _wrappedValue: T {
        @_transparent get {
            memoryLayout.0
        }
        @_transparent set {
            self = .atomic(innerValue: newValue, semaphore: semaphore)
        }
    }
    
    public var wrappedValue: T {
        @_transparent get {
            semaphore.wait()
            let returnValue = _wrappedValue
            semaphore.signal()
            return returnValue
        }
        @_transparent set {
            semaphore.wait()
            _wrappedValue = newValue
            semaphore.signal()
        }
    }
    
    @_transparent public init(wrappedValue: T) {
        self = .atomic(innerValue: wrappedValue, semaphore: DispatchSemaphore(value: 1))
    }
}
