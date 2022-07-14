//
//  File 2.swift
//  
//
//  Created by Eric Rabil on 7/5/22.
//

import Foundation
import Combine
#if canImport(Swog)
import Swog
#endif

public class ERTimer {
    #if DEBUG && canImport(Swog)
    public static let log = Logger(category: "ERTimer")
    public var log: Swog.Logger { ERTimer.log }
    #endif
    
    fileprivate let timer: DispatchSourceTimer
    
    public init(queue: DispatchQueue = .global(qos: .utility), callback: @escaping () -> ()) {
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.setEventHandler(handler: callback)
    }
    
    public convenience init(scheduledFromNow: DispatchTimeInterval, queue: DispatchQueue = .global(qos: .utility), callback: @escaping () -> ()) {
        self.init(queue: queue, callback: callback)
        timer.schedule(deadline: .now().advanced(by: scheduledFromNow))
        #if DEBUG && canImport(Swog)
        log.info("Scheduled timer for \(String(describing: scheduledFromNow))")
        #endif
        timer.resume()
    }
    
    deinit {
        #if DEBUG && canImport(Swog)
        log.info("I am deallocating!")
        #endif
        timer.cancel()
    }
    
    public func reschedule(fromNow: DispatchTimeInterval) {
        timer.suspend()
        timer.schedule(deadline: .now().advanced(by: fromNow))
        #if DEBUG && canImport(Swog)
        log.info("Rescheduled timer for \(String(describing: fromNow))")
        #endif
        timer.resume()
    }
}

public class ERControllableTimer: ERTimer {
    #if DEBUG && canImport(Swog)
    public override var log: Swog.Logger { .init(category: "ERControllableTimer") }
    #endif
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var enabled = false
    @Published public var interval: DispatchTimeInterval
    private var suspended = true
    
    public required init(interval: DispatchTimeInterval, queue: DispatchQueue = .global(qos: .utility), callback: @escaping () -> ()) {
        self.interval = interval
        super.init(queue: queue, callback: callback)
        Publishers.CombineLatest($enabled, $interval).sink { enabled, interval in
            if enabled {
                #if DEBUG && canImport(Swog)
                self.log.info("Rescheduling timer for every \(String(describing: interval))")
                #endif
                self.timer.schedule(deadline: .now().advanced(by: interval), repeating: interval)
                if self.suspended {
                    #if DEBUG && canImport(Swog)
                    self.log.info("Resuming timer")
                    #endif
                    self.timer.resume()
                    self.suspended = false
                }
            } else if !self.suspended {
                #if DEBUG && canImport(Swog)
                self.log.info("Suspending timer")
                #endif
                self.timer.suspend()
                self.suspended = true
            }
        }.store(in: &cancellables)
    }
    
    @available(*, unavailable)
    public override func reschedule(fromNow: DispatchTimeInterval) {
        
    }
}

public class ERExponentialTimer {
    #if DEBUG && canImport(Swog)
    public static let log = Logger(category: "ERExponentialTimer")
    public var log: Swog.Logger { ERTimer.log }
    #endif
    
    private var timer: ERTimer?
    public let base: DispatchTimeInterval
    public let growthRate: Double
    
    public private(set) var attempts: Int = 0 {
        didSet {
            #if DEBUG && canImport(Swog)
            log.info("Incremented attempts to \(self.attempts)")
            #endif
        }
    }
    
    public var modifier: Double {
        pow(growthRate, Double(attempts))
    }
    
    public var waitPeriod: DispatchTimeInterval {
        switch base {
        case .seconds(let seconds):
            return .milliseconds(Int(Double(seconds * 1000) * modifier))
        case .milliseconds(let milliseconds):
            return .milliseconds(Int(Double(milliseconds) * modifier))
        case .nanoseconds(let nanosecnds):
            return .nanoseconds(Int(Double(nanosecnds) * modifier))
        case .microseconds(let microseconds):
            return .microseconds(Int(Double(microseconds) * modifier))
        case .never:
            return .never
        @unknown case _:
            return .never
        }
    }
    
    public init(base: DispatchTimeInterval, queue: DispatchQueue = .global(qos: .utility), growthRate: Double = 1.0, callback: @escaping () -> Bool) {
        self.base = base
        self.growthRate = growthRate
        timer = ERTimer(scheduledFromNow: base, queue: queue, callback: {
            let attempts = self.attempts + 1
            #if DEBUG && canImport(Swog)
            self.log.info("Incrementing attempts to \(attempts)")
            #endif
            self.attempts = attempts
            if callback() {
                self.timer!.reschedule(fromNow: self.waitPeriod)
            }
        })
    }
    
    public func schedule() {
        #if DEBUG && canImport(Swog)
        log.info("Scheduling for \(String(describing: self.waitPeriod)) from now")
        #endif
        timer!.reschedule(fromNow: waitPeriod)
    }
    
    public func cancel() {
        timer!.timer.cancel()
    }
}
