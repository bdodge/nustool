//
//  TCPserver.swift
//  magtool
//
//  Created by Brian Dodge on 3/26/22.
//  Copyright © 2022 Brian Dodge. All rights reserved.
//

import Foundation

class SocketServer {
    
    var sock_fd : Int32 = -1
    var client_fd : Int32 = -1
    
    var isAccepting: Bool = false
    
    func fdZero(fdset: inout fd_set) {
        fdset.fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    
    func fdSet(fd: Int32, fdset: inout fd_set) {
        let intOffset = Int(fd / 32)
        let bitOffset = fd % 32
        let mask = 1 << bitOffset
        
        switch intOffset {
        case 0: fdset.fds_bits.0 = fdset.fds_bits.0 | Int32(mask)
        case 1: fdset.fds_bits.1 = fdset.fds_bits.1 | Int32(mask)
        case 2: fdset.fds_bits.2 = fdset.fds_bits.2 | Int32(mask)
        case 3: fdset.fds_bits.3 = fdset.fds_bits.3 | Int32(mask)
        case 4: fdset.fds_bits.4 = fdset.fds_bits.4 | Int32(mask)
        case 5: fdset.fds_bits.5 = fdset.fds_bits.5 | Int32(mask)
        case 6: fdset.fds_bits.6 = fdset.fds_bits.6 | Int32(mask)
        case 7: fdset.fds_bits.7 = fdset.fds_bits.7 | Int32(mask)
        case 8: fdset.fds_bits.8 = fdset.fds_bits.8 | Int32(mask)
        case 9: fdset.fds_bits.9 = fdset.fds_bits.9 | Int32(mask)
        case 10: fdset.fds_bits.10 = fdset.fds_bits.10 | Int32(mask)
        case 11: fdset.fds_bits.11 = fdset.fds_bits.11 | Int32(mask)
        case 12: fdset.fds_bits.12 = fdset.fds_bits.12 | Int32(mask)
        case 13: fdset.fds_bits.13 = fdset.fds_bits.13 | Int32(mask)
        case 14: fdset.fds_bits.14 = fdset.fds_bits.14 | Int32(mask)
        case 15: fdset.fds_bits.15 = fdset.fds_bits.15 | Int32(mask)
        case 16: fdset.fds_bits.16 = fdset.fds_bits.16 | Int32(mask)
        case 17: fdset.fds_bits.17 = fdset.fds_bits.17 | Int32(mask)
        case 18: fdset.fds_bits.18 = fdset.fds_bits.18 | Int32(mask)
        case 19: fdset.fds_bits.19 = fdset.fds_bits.19 | Int32(mask)
        case 20: fdset.fds_bits.20 = fdset.fds_bits.20 | Int32(mask)
        case 21: fdset.fds_bits.21 = fdset.fds_bits.21 | Int32(mask)
        case 22: fdset.fds_bits.22 = fdset.fds_bits.22 | Int32(mask)
        case 23: fdset.fds_bits.23 = fdset.fds_bits.23 | Int32(mask)
        case 24: fdset.fds_bits.24 = fdset.fds_bits.24 | Int32(mask)
        case 25: fdset.fds_bits.25 = fdset.fds_bits.25 | Int32(mask)
        case 26: fdset.fds_bits.26 = fdset.fds_bits.26 | Int32(mask)
        case 27: fdset.fds_bits.27 = fdset.fds_bits.27 | Int32(mask)
        case 28: fdset.fds_bits.28 = fdset.fds_bits.28 | Int32(mask)
        case 29: fdset.fds_bits.29 = fdset.fds_bits.29 | Int32(mask)
        case 30: fdset.fds_bits.30 = fdset.fds_bits.30 | Int32(mask)
        case 31: fdset.fds_bits.31 = fdset.fds_bits.31 | Int32(mask)
        default: break
        }
    }
    
    func Init(port: UInt16) -> Bool {
        
        // make sure no open sockets around
        Close();
        
        sock_fd = socket(AF_INET, SOCK_STREAM, 0);
        if sock_fd == -1 {
            perror("Failure: creating socket")
            return false
        }

        var sock_opt_on = Int32(1)
        
        setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

        var server_addr = sockaddr_in()
        let server_addr_size = socklen_t(MemoryLayout.size(ofValue: server_addr))

        server_addr.sin_len = UInt8(server_addr_size)
        server_addr.sin_family = sa_family_t(AF_INET) // chooses IPv4
        server_addr.sin_port = UInt16(port).bigEndian // chooses the port

        let bind_server = withUnsafePointer(to: &server_addr) {
            bind(sock_fd, UnsafeRawPointer($0).assumingMemoryBound(to: sockaddr.self), server_addr_size)
        }
        
        if bind_server == -1 {
            perror("Failure: binding port")
            close(sock_fd)
            sock_fd = -1;
            return false
        }

        if listen(sock_fd, 5) == -1 {
            perror("Failure: listening")
            close(sock_fd)
            sock_fd = -1;
            return false
        }
        
        return true
    }

    func IsConnected() -> Bool {
        return client_fd >= 0
    }
    
    func IsAccepting() -> Bool {
        return isAccepting
    }

    func Accept() -> Bool {
        var client_addr = sockaddr_storage()
        var client_addr_len = socklen_t(MemoryLayout.size(ofValue: client_addr))
        
        isAccepting = true
        
        if sock_fd < 0 {
            print("Accept on bad server sock?")
            return false
        }
        
        client_fd = withUnsafeMutablePointer(to: &client_addr) {
            accept(sock_fd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), &client_addr_len)
        }
        
        isAccepting = false

        if client_fd == -1 {
            perror("Failure: accepting connection")
            return false
        }
        
        var sock_opt_on = Int32(1)

        setsockopt(client_fd, IPPROTO_TCP, TCP_NODELAY, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

        let ret = fcntl(client_fd, F_SETFL, O_NONBLOCK);
        
        if ret < 0 {
            perror("Failure: set non-blocking")
            close(client_fd)
            client_fd = -1
            return false
        }

         return true
    }
    
    func PollClient(forReading: Bool, timeoutMS: Int) -> Int32 {
        if client_fd < 0 {
            return -1;
        }
        let numOfFd:Int32 = client_fd + 1
        let tos : Int32 = Int32(timeoutMS / 1000)
        let tous : Int32 = Int32((timeoutMS - Int(tos) * 1000) * 1000)
        var timeout:timeval = timeval(tv_sec: __darwin_time_t(tos), tv_usec: tous)
        var the_fds:fd_set = fd_set()
        
        fdZero(fdset: &the_fds);
        fdSet(fd: client_fd, fdset: &the_fds)
        
        if forReading {
            return select(numOfFd, &the_fds, nil, nil, &timeout);
        } else {
            return select(numOfFd, &the_fds, nil, nil, &timeout);
        }
    }
    
    func Send(data: String) -> Bool {
        if client_fd < 0 {
            return false
        }
        let databytes = [UInt8](data.utf8)
        let len = databytes.count
        let wc = write(client_fd, databytes, len)
        
        if wc < 0 {
            if errno == EINTR || errno == EAGAIN {
                return false
            }
            perror("Failure: write")
            close(client_fd)
            client_fd = -1;
            return false
        }
        
        if wc < len {
            print("WC < len in write")
        }
        
        return true
    }
    
    func Recv(maxLength : Int) -> String? {
        if client_fd < 0 {
            return nil
        }
        
        var databytes = [UInt8](repeating: 0, count: maxLength)

        let sv = PollClient(forReading: true, timeoutMS: 20)
        if sv < 0 {
            perror("Failure: select")
            close(client_fd)
            client_fd = -1;
            return nil
        }
        
        if sv == 0 {
            return nil
        }
        
        let rc = read(client_fd, &databytes, maxLength)
        if rc < 0 {
            if errno == EINTR || errno == EAGAIN {
                return nil
            }
            perror("Failure: read")
            close(client_fd)
            client_fd = -1;
            return nil
        }
        
        if rc == 0 {
            // 0 read after successful select means socket closed
            // on remote side
            close(client_fd)
            client_fd = -1;
            return nil
        }
        
        let actualbytes = databytes[0..<rc]
        
        if let data = String(bytes: actualbytes, encoding: .utf8) {
            return data
        }
        
        return nil
    }

    func Close() {
        if client_fd >= 0 {
            close(client_fd)
            client_fd = -1
        }
        if sock_fd >= 0 {
            close(sock_fd)
            sock_fd = -1
        }
    }
}
