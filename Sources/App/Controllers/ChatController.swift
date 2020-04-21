//
//  ChatController.swift
//  App
//
//  Created by Mher Davtyan on 2/20/20.
//

import Vapor
import Crypto
import FluentSQLite

struct ChatController: RouteCollection {
    
    func boot(router: Router) throws {
        router.get("chats", use: all)
        router.delete("chats", use: delete)
        
        /// CurrentUserMiddleware
        let currentUserRoutes = router.grouped(CurrentUserMiddleware())
        currentUserRoutes.post("chats", "group", use: group)
        
        /// CreateChatMiddleware
        let singleChatRoute = currentUserRoutes.grouped(CreateChatMiddleware())
        singleChatRoute.post("chats", use: single)
        
        let invitationRoute = router.grouped(InvitationMiddleware())
        invitationRoute.put("chats", "invite", use: invite)
    }
    
    // MARK: - Post Requests
    /// Create a single chat
    private func single(_ req: Request) throws -> Future<Chat> {
        try User.current(req).flatMap(to: Chat.self) { current in
            let id = req.query[String.self, at: "id"]
            
            return User.query(on: req)
                .filter(\User.id, .equal, UUID(id ?? ""))
                .first().flatMap(to: Chat.self) { user in
                    try req.content.decode(Chat.self).save(on: req).flatMap { chat in
                        chat.members = [current, user!]
                        chat.created = Date()
                        let _ = chat.save(on: req)
                        
                        return chat.users.attach(user!, on: req).flatMap(to: Chat.self) { _ in
                            chat.users.attach(current, on: req).map(to: Chat.self) { _ in
                                chat
                            }
                        }
                    }
            }
        }
    }
    
    /// Create a group chat
    private func group(_ req: Request) throws -> Future<Chat> {
        return try User.current(req).flatMap(to: Chat.self) { current in
            try req.content.decode(Chat.self).save(on: req).flatMap { chat in
                chat.members = [current]
                chat.created = Date()
                let _ = chat.save(on: req)
                
                return chat.users.attach(current, on: req).map(to: Chat.self) { _ in chat }
            }
        }
    }
    
    /// Create a group chat
    private func invite(_ req: Request) throws -> Future<Chat> {
        return try User.current(req).flatMap(to: Chat.self) { current in
            let c_id = req.query[String.self, at: "c_id"]
            let u_id = req.query[String.self, at: "u_id"]
            let c_uuid = UUID(c_id ?? "")
            let u_uuid = UUID(u_id ?? "")
            
            return flatMap(to: Chat.self, Chat.find(c_uuid ?? UUID(), on: req), User.find(u_uuid ?? UUID(), on: req)) { chat, user in
                chat!.users.attach(user!, on: req).flatMap(to: Chat.self) { _ in
                    chat?.members?.append(user!)
                    return chat!.save(on: req)
                }
            }
        }
    }
    
    private func all(_ req: Request) throws -> Future<[Chat]> {
        Chat.query(on: req).all()
    }
    
    private func delete(_ req: Request) throws -> Future<HTTPStatus> {
        Chat.query(on: req).delete().transform(to: .noContent)
    }
}
