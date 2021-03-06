//    The MIT License (MIT)
//
//    Copyright (c) 2016 soh335
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

import Foundation

import Darwin

public func GetBSDProcessList() -> [kinfo_proc]  {

    var done = false
    var result: [kinfo_proc]?
    var err: Int32

    repeat {
        let name = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0];
        let namePointer = name.withUnsafeBufferPointer { UnsafeMutablePointer<Int32>(mutating: $0.baseAddress) }
        var length: Int = 0
        
        err = sysctl(namePointer, u_int(name.count), nil, &length, nil, 0)
        if err == -1 {
            err = errno
        }
    
        if err == 0 {
            let count = length / MemoryLayout<kinfo_proc>.stride
            result = [kinfo_proc].init(repeating: kinfo_proc(), count: count)
            err = result!.withUnsafeMutableBufferPointer({ ( p: inout UnsafeMutableBufferPointer<kinfo_proc>) -> Int32 in
                return sysctl(namePointer, u_int(name.count), p.baseAddress, &length, nil, 0)
            })
            switch err {
            case 0:
                done = true
            case -1:
                err = errno
            case ENOMEM:
                err = 0
            default:
                fatalError()
            }
        }
    } while err == 0 && !done

    return result ?? []
}

public func NSUsernameForUserIdentifier(_ identifier: uid_t) -> String! {
    if let pwuid = getpwuid(identifier), let name = pwuid.pointee.pw_name {
        return String(cString: name)
    }
    return nil
}

public extension kinfo_proc {
    var processName: String {
        withUnsafePointer(to: kp_proc.p_comm) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: $0)) {
                String(cString: $0)
            }
        }
    }
    
    var ownerUID: uid_t {
        kp_eproc.e_ucred.cr_uid
    }
    
    var ownerName: String {
        NSUsernameForUserIdentifier(ownerUID) ?? "(nil)"
    }
}

