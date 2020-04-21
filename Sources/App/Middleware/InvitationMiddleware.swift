//
//  InvitationMiddleware.swift
//  App
//
//  Created by Mher Davtyan on 3/3/20.
//

import Vapor

final class InvitationMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard let c_id = request.query[String.self, at: "c_id"],
            let u_id = request.query[String.self, at: "u_id"],
            let c_uuid = UUID(c_id),
            let u_uuid = UUID(u_id) else { throw Abort.wrongParameters }
        
        return flatMap(to: Response.self, Chat.find(c_uuid, on: request), User.find(u_uuid, on: request)) { chat, user in
            guard let u = user else { throw Abort.wrongParameters }
            
            return try u.chats.query(on: request).all().flatMap(to: Response.self) { chats in
                try chats.forEach { if $0.id == chat?.id { throw Abort.alreadyInvited }}
                return try next.respond(to: request)
            }
        }
    }
}
