//
//  File.swift
//  
//
//  Created by Eric Rabil on 8/24/21.
//

import Foundation

public enum XPCError: Error {
    case missing_bootstrap_port(uid_t)
}

public func find_bootstrap_port(forUID uid: uid_t) -> bootstrap_t? {
    var task: task_t = 0
    var bs_port: mach_port_t = 0
    
    let tasks = GetBSDProcessList().filter {
        $0.ownerUID == uid
    }.map(\.kp_proc.p_pid)
    
    for pid in tasks {
        guard task_for_pid(mach_task_self_, pid, &task) == KERN_SUCCESS else {
            continue
        }
        
        guard task_get_special_port(task, TASK_BOOTSTRAP_PORT, &bs_port) == KERN_SUCCESS else {
            continue
        }
        
        guard bs_port != bootstrap_port else {
            continue
        }
        
        return bs_port
    }
    
    return nil
}

public func xpc_impersonate_user<R>(_ uid: uid_t, _ context: () throws -> R) throws -> R {
    let old_bootstrap_port = bootstrap_port
    defer { bootstrap_port = old_bootstrap_port }
    
    guard let target_bootstrap_port = find_bootstrap_port(forUID: uid) else {
        throw XPCError.missing_bootstrap_port(uid)
    }
    
    bootstrap_port = target_bootstrap_port
    return try context()
}
