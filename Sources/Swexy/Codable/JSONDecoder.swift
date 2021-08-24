//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/19/21.
//

import Foundation

public extension JSONDecoder {
    private class CustomDecodable: Decodable {
        static var decoder: ((Decoder) throws -> Any)!
        
        let decodedValue: Any
        
        required init(from decoder: Decoder) throws {
            decodedValue = try Self.decoder(decoder)
        }
    }
    
    func decode<P>(data: Data, _ cb: @escaping (Decoder) throws -> P) throws -> P {
        // this would be better but we cant have anonymous classes yet so fuck you and also JSONParser is marked internal so fuck you
        CustomDecodable.decoder = cb
        defer { CustomDecodable.decoder = nil }
        return try decode(CustomDecodable.self, from: data).decodedValue as! P
    }
}
