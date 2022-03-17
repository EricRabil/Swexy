//
//  File.swift
//  
//
//  Created by Eric Rabil on 3/15/22.
//

import Foundation

private func _NSLookupProcessesAtPath(_ path: Int32...) -> [kinfo_proc] {
    let pathCount = u_int(path.count)
    var length: Int = 0
    
    return path.withUnsafeBufferPointer { pathBuffer in
        switch sysctl(UnsafeMutablePointer(mutating: pathBuffer.baseAddress!), pathCount, nil, &length, nil, 0) {
        case 0:
            let count = length / MemoryLayout<kinfo_proc>.stride
            var result = [kinfo_proc](repeating: kinfo_proc(), count: count)
            switch sysctl(UnsafeMutablePointer(mutating: pathBuffer.baseAddress!), pathCount, &result, &length, nil, 0) {
            case 0:
                return result
            case let error:
                break
            }
        case let error:
            break
        }
        
        return []
    }
}

public func NSLookupProcessesForUser(uid: uid_t) -> [kinfo_proc] {
    _NSLookupProcessesAtPath(CTL_KERN, KERN_PROC, KERN_PROC_UID, Int32(uid))
}

public func NSLookupProcessesForUser(ruid: uid_t) -> [kinfo_proc] {
    _NSLookupProcessesAtPath(CTL_KERN, KERN_PROC, KERN_PROC_RUID, Int32(ruid))
}

public func NSLookupProcessesForProcessGroup(pid: pid_t) -> [kinfo_proc] {
    _NSLookupProcessesAtPath(CTL_KERN, KERN_PROC, KERN_PROC_PGRP, Int32(pid))
}

public func NSLookupAllProcesses() -> [kinfo_proc] {
    _NSLookupProcessesAtPath(CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0)
}

public func NSLookupProcessInfo(_ processIdentifier: pid_t) -> kinfo_proc? {
    var proc: kinfo_proc = kinfo_proc()
    var procSize = MemoryLayout<kinfo_proc>.size
    var path = [CTL_KERN, KERN_PROC, KERN_PROC_PID, processIdentifier]
    
    if sysctl(&path, 4, &proc, &procSize, nil, 0) == 0, procSize > 0 {
        return proc
    }
    
    return nil
}

public func NSUserIdentifierFromProcessIdentifier(_ processIdentifier: pid_t) -> uid_t? {
    NSLookupProcessInfo(processIdentifier)?.kp_eproc.e_ucred.cr_uid
}
