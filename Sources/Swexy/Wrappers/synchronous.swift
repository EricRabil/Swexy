//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/24/21.
//

import Foundation

/**
 Wraps a property to make it synchronously accessed over the main thread
 */
@propertyWrapper
public struct synchronous<Wrapped> {
    public var _wrappedValue: Wrapped
    
    @_transparent
    public var wrappedValue: Wrapped {
        get {
            onMain(_wrappedValue)
        }
        set {
            onMain(_wrappedValue = newValue)
        }
    }
    
    public init(wrappedValue: Wrapped) {
        _wrappedValue = wrappedValue
    }
}
