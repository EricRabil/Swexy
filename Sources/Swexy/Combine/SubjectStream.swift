//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/24/21.
//

import Foundation
import Combine

// oh yack yack fing yack apple
@_silgen_name("dispatch_get_current_queue")
func dispatch_get_current_queue() -> DispatchQueue

public class SubjectStream<Element> {
    private let subject = PassthroughSubject<Element, Never>()
    private let publisher: Publishers.Share<PassthroughSubject<Element, Never>>
    
    @synchronous
    private var cancellables = Set<AnyCancellable>()
    
    /**
     Initializes the SubjectStream.
     
     - Parameter publish: the value of this parameter will be assigned a function which is used to send elements down the stream.
     */
    public init(publish: inout (Element) -> ()) {
        publisher = subject.share()
        publish = subject.send(_:)
    }
    
    /**
     Subscribes to the stream, returning a callback which unsubscribes when invoked.
     Discarding the return value means you cannot unsubscribe from this stream.
     
     - Parameter cb: The closure to be invoked when a new element is sent
     
     - Returns a callback which unsubscrubes when invoked
     */
    @discardableResult
    public func subscribe(_ cb: @escaping (Element) -> ()) -> () -> () {
        let cancellable = publisher
            .receive(on: dispatch_get_current_queue())
            .sink(receiveValue: cb)
        
        cancellable.store(in: &cancellables)
        
        return {
            cancellable.cancel()
            self.cancellables.remove(cancellable)
        }
    }
}

// MARK: - Declarative temporary subscriptions
@available(macOS 10.15, iOS 13.0, *)
public extension SubjectStream {
    @discardableResult
    func once(_ cb: @escaping (Element) -> ()) -> () -> () {
        var unsubscribe: (() -> ())!
        
        unsubscribe = subscribe { item in
            unsubscribe()
            cb(item)
        }
        
        return unsubscribe
    }
    
    @discardableResult
    func once(where valid: @escaping (Element) -> Bool, _ cb: @escaping (Element) -> ()) -> () -> () {
        var unsubscribe: (() -> ())!
        
        unsubscribe = subscribe { item in
            guard valid(item) else {
                return
            }
            
            unsubscribe()
            cb(item)
        }
        
        return unsubscribe
    }
}
