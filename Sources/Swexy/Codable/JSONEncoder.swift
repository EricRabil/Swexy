//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/19/21.
//

import Foundation

public extension JSONEncoder {
    private class CustomEncodable: Encodable {
        private let encode: (Encoder) throws -> ()
        
        init(_ encode: @escaping (Encoder) throws -> ()) {
            self.encode = encode
        }
        
        func encode(to encoder: Encoder) throws {
            try encode(encoder)
        }
    }
    
    func encode(_ cb: @escaping (Encoder) throws -> ()) throws -> Data {
        try encode(CustomEncodable(cb))
    }
}
