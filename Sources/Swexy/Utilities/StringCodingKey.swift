//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 8/28/22.
//

import Foundation

public struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {
    public var stringValue: String
    
    public init(stringLiteral value: String) {
        self.init(stringValue: value)
    }
    
    public init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public var intValue: Int? {
        get {
            Int(stringValue)
        }
        set {
            newValue.map {
                stringValue = $0.description
            }
        }
    }
    
    public init(intValue: Int) {
        self.stringValue = intValue.description
    }
}
