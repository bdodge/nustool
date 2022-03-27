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
        
        if client_fd == -1 {
            perror("Failure: accepting connection")
            isAccepting = false
            return false
        }
        
        var sock_opt_on = Int32(1)

        setsockopt(client_fd, IPPROTO_TCP, TCP_NODELAY, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

        fcntl(client_fd, F_SETFL, O_NONBLOCK);

        isAccepting = false
        return true
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
