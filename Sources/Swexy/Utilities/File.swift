//
//  File.swift
//  
//
//  Created by Eric Rabil on 3/15/22.
//

import Foundation

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
