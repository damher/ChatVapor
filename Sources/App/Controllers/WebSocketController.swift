//
//  WebSocketController.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor

struct WebSocketController: WSRouteCollection {
    
    static var channels: [String: WebSocket] = [:]
    
    func boot(router: NIOWebSocketServer) throws {
        router.get("chats", use: chats)
        router.get("messages", Chat.parameter, use: messages)
        router.get("send", Chat.parameter, use: send)
        router.get("notifier", User.parameter, use: notifier)
        router.get("read", Chat.parameter, use: read)
    }
    
    // MARK: - Requests
    /// Notify user about new chat
    func notifier(_ ws: WebSocket, _ req: Request) {
        let _ = self.current(req).map { current in
            let _ = try req.parameters.next(User.self).map { user in
                guard let currentUserId = current.id else { throw Abort.notLogged }
                guard let userId = user.id else { throw Abort.wrongParameters }
                
                /// Add `WebSocket` to sockets dictionary
                DispatchQueue.global().sync {
                    WebSocketController.channels["notifier" + userId.uuidString + currentUserId.uuidString] = ws
                }
                
                ws.onBinary { ws, data in
                    
                    /// Send data
                    for element in WebSocketController.channels {
                        if element.key.hasPrefix("notifier" + userId.uuidString) {
                            if !element.value.isClosed {
                                element.value.send(data)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Send message
    func send(_ ws: WebSocket, _ req: Request) throws {
        let _ = try User.current(req).map { current in
            let _ = try req.parameters.next(Chat.self).map { chat in
                guard let userId = current.id else { throw Abort.notLogged }
                guard let chatId = chat.id else { throw Abort.wrongParameters }
                
                /// Add `WebSocket` to sockets dictionary
                DispatchQueue.global().sync {
                    WebSocketController.channels["send" + chatId.uuidString + userId.uuidString] = ws
                }
                
                ws.onBinary { ws, data in
                    let _ = Chat.query(on: req).filter(\Chat.id, .equal, chatId).first().map { updatedChat in
                        
                        /// Convert `Data` to `Message`
                        let _ = self.dataToMessage(req, data: data, id: chatId).map { msg in
                            
                            /// Update chat
                            updatedChat?.last_message = msg
                            let _ = updatedChat?.save(on: req)
                            
                            var members = updatedChat?.members
                            members?.removeAll(where: { $0.id == current.id })
                            
                            if members?.count == 0 {
                                
                                /// Convert `Message` to `Data`
                                let response = try JSONEncoder().encode(msg)
                                
                                /// Send data
                                for element in WebSocketController.channels {
                                    if element.key.hasPrefix("send" + chatId.uuidString) {
                                        if !element.value.isClosed {
                                            element.value.send(response)
                                        }
                                    }
                                }
                            } else {
                                let _ = members?.map { member in
                                    if let memberId = member.id {
                                        
                                        /// Update chat members
                                        let _ = self.updateMember(req, memberId: memberId, chatId: chatId).map { _ in
                                            
                                            /// Convert `Message` to `Data`
                                            let response = try JSONEncoder().encode(msg)
                                            
                                            /// Send data
                                            for element in WebSocketController.channels {
                                                if element.key.hasPrefix("send" + chatId.uuidString) {
                                                    if !element.value.isClosed {
                                                        element.value.send(response)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Update messages
    func messages(_ ws: WebSocket, _ req: Request) throws {
        let _ = try map(currentId(req), req.parameters.next(Chat.self), { (current_id, chat) in
            guard let id = chat.id?.uuidString else { throw Abort.wrongParameters }
            
            /// Add `WebSocket` to sockets dictionary
            DispatchQueue.global().sync {
                WebSocketController.channels["messages" + id + current_id.uuidString] = ws
            }
            
            ws.onBinary { ws, data_ in
                do {
                    let _ = try chat.messages.query(on: req).all().map { messages in
                        
                        /// Convert `[Message]` to `Data`
                        let response = try JSONEncoder().encode(messages)
                        
                        /// Send data
                        for element in WebSocketController.channels {
                            if element.key == "messages" + id + current_id.uuidString {
                                if !element.value.isClosed {
                                    element.value.send(response)
                                }
                            }
                        }
                    }
                } catch {
                    debugPrint(error)
                }
            }
        })
    }
    
    /// Read messages
    func read(_ ws: WebSocket, _ req: Request) throws {
        let _ = self.current(req).map { current in
            let _ = try req.parameters.next(Chat.self).map { chat in
                guard let userId = current.id else { throw Abort.notLogged }
                guard let chatId = chat.id else { throw Abort.wrongParameters }
                
                /// Add `WebSocket` to sockets dictionary
                DispatchQueue.global().sync {
                    WebSocketController.channels["read" + chatId.uuidString + userId.uuidString] = ws
                }
                
                ws.onBinary { ws, data in
                    let _ = self.current(req).map { updatedCurrent in
                        updatedCurrent.uncheckedChats?[chatId] = 0
                        let _ = updatedCurrent.save(on: req)
                        
                        /// Send data
                        for element in WebSocketController.channels {
                            if element.key == "read" + chatId.uuidString + userId.uuidString {
                                if !element.value.isClosed {
                                    element.value.send(data)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Update chats
    func chats(_ ws: WebSocket, _ req: Request) throws {
        let _ = current(req).map { user in
            guard let id = user.id else { throw Abort.notLogged }
            
            /// Add `WebSocket` to sockets dictionary
            DispatchQueue.global().sync {
                WebSocketController.channels["chats" + id.uuidString] = ws
            }
            
            ws.onBinary { ws, data_ in
                
                /// Delete unused chats
                let _ = Chat.query(on: req).group(.and) { and in
                    and.filter(\.last_message?.text, .equal, nil)
                    and.filter(\.group, .equal, false)
                }.delete().map { _ in
                    let _ = self.current(req).map { updatedCurrent in
                        let _ = try updatedCurrent.chats.query(on: req).all().map { chats in
                            var chats_ = chats
                            
                            /// Delete current user from members
                            chats_.forEach { c in
                                if let id = c.id {
                                    c.members?.removeAll(where: { $0.id == updatedCurrent.id })
                                    c.unread_count = updatedCurrent.uncheckedChats?[id] ?? 0
                                }
                            }
                            /// Sort by last message create date
                            try chats_.sort {
                                let date_1 = $0.last_message?.created ?? $0.created
                                let date_2 = $1.last_message?.created ?? $1.created
                                guard date_2 != nil else { throw Abort.notFound }
                                return date_1?.compare(date_2!) == ComparisonResult.orderedDescending
                            }
                            
                            /// Convert `[Chat]` to `Data`
                            let response = try JSONEncoder().encode(chats_)
                            
                            /// Send data
                            for element in WebSocketController.channels {
                                if element.key == "chats" + id.uuidString {
                                    if !element.value.isClosed {
                                        element.value.send(response)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension WebSocketController {
    
    // MARK: - Other methods
    /// Current user
    func current(_ req: Request) -> Future<User> {
        let id = req.http.headers.firstValue(name: .init("id")) ?? ""
        let token = req.http.headers.firstValue(name: .init("token"))
        
        return User.query(on: req).group(.and) { and in
            and.filter(\User.id, .equal, UUID(id))
            and.filter(\User.token, .equal, token)
            and.filter(\User.authorized, .equal, true)
            and.filter(\User.logged, .equal, true)
        }.first().map { user in
            guard let u = user else { throw Abort.notLogged }
            return u
        }
    }
    
    /// Current user's `UUID`
    func currentId(_ req: Request) throws -> Future<UUID> {
        current(req).map { user in
            guard let id = user.id else { throw Abort.notLogged }
            return id
        }
    }
    
    /// Convert `Data` to `Message`
    func dataToMessage(_ req: Request, data: Data, id: UUID) -> Future<Message> {
        self.current(req).flatMap(to: Message.self) { user in
            let msg = try JSONDecoder().decode(Message.self, from: data)
            try msg.validate()
            msg.sender = user
            msg.created = Date()
            msg.chatID = id
            return msg.save(on: req)
        }
    }
    
    /// Update chat member
    func updateMember(_ req: Request, memberId: UUID, chatId: UUID) -> Future<User> {
        User.find(memberId, on: req).flatMap { user in
            if user?.uncheckedChats == nil {
                user?.uncheckedChats = [:]
            } else {
                if user?.uncheckedChats?[chatId] == nil {
                    user?.uncheckedChats?[chatId] = 1
                } else {
                    user?.uncheckedChats?[chatId]! += 1
                }
            }
            guard let u = user else { throw Abort.wrongParameters }
            
            return u.save(on: req)
        }
    }
}
