//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/24/21.
//

#if canImport(Combine)

import Foundation

/**
 A subclass of SubjectStream whose publish function is publicly accessible rather than passed via initializer.
 */
@available(macOS 10.15, iOS 13.0, *)
public class OpenSubjectStream<Element>: SubjectStream<Element> {
    public private(set) var publish: (Element) -> () = { _ in }
    
    public init() {
        super.init(publish: &publish)
    }
}
#endif
