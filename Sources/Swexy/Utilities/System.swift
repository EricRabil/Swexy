//
//  System.swift
//  
//
//  Created by Eric Rabil on 3/17/22.
//

import Foundation

/// This will return the public-facing IP address for Macs that have a WAN IP hooked up to their ethernet port
public func NSGetEthernetIPAddress(_ targetFamily: Int32 = AF_INET) -> String {
    var ifaddrs: UnsafeMutablePointer<ifaddrs>? = nil
    guard getifaddrs(&ifaddrs) == 0 else {
        return ""
    }
    while let ifaddr = ifaddrs?.pointee {
        defer {
            ifaddrs = ifaddrs?.pointee.ifa_next
        }
        guard let family = ifaddr.ifa_addr?.pointee.sa_family else {
            continue
        }
        guard family == sa_family_t(targetFamily) else {
            continue
        }
        switch String(cString: ifaddr.ifa_name) {
        case "en0", "en2", "en3", "en4", "pdp_ip0", "pdp_ip1", "pdp_id2", "pdp_id3":
            let flags = ifaddr.ifa_flags
            guard Int32(flags) & IFF_UP == IFF_UP else {
                continue
            }
            guard Int32(flags) & IFF_RUNNING == IFF_RUNNING else {
                continue
            }
            guard Int32(flags) & IFF_LOOPBACK != IFF_LOOPBACK else {
                continue
            }
            guard var addr = ifaddr.ifa_addr?.pointee else {
                continue
            }
            return String(cString: &addr.sa_data.0)
        default:
            break
        }
    }
    return "-"
}

/// For some reason all the Cocoa APIs return something other than what `hostname` returns, someone wanted to be innovative I guess
public func NSGetTrueHostname() -> String {
    let hostname = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXHOSTNAMELEN))
    defer {
        hostname.deallocate()
    }
    guard gethostname(hostname, Int(MAXHOSTNAMELEN)) == 0 else {
        return "-"
    }
    return String(cString: hostname)
}

public func NSGetTimeIntervalOfBoot() -> TimeInterval? {
    var path = [CTL_KERN, KERN_BOOTTIME]
    
    var now: timeval = timeval(), tz = timezone()
    guard gettimeofday(&now, &tz) == 0 else {
        return nil
    }
    
    var boottime = timeval(), size = MemoryLayout<timeval>.size
    guard sysctl(&path, 2, &boottime, &size, nil, 0) == 0 else {
        return nil
    }
    
    var uptime: TimeInterval = TimeInterval(boottime.tv_sec)
    uptime += Double(boottime.tv_usec) / 1000000.0
    return uptime
}

public func NSGetTimeOfBoot() -> Date? {
    NSGetTimeIntervalOfBoot().map(Date.init(timeIntervalSince1970:))
}
