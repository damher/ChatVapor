//
//  ChatMiddleware.swift
//  App
//
//  Created by Mher Davtyan on 2/20/20.
//

import Vapor

final class CreateChatMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard let id = request.query[String.self, at: "id"] else {
            throw Abort.notFound
        }
        
        return flatMap(to: Response.self,
                       try User.current(request),
                       User.query(on: request).filter(\User.id, .equal, UUID(id)).first()) { current, user in
                    
                        
                        flatMap(to: Response.self,
                                try current.chats.query(on: request).filter(\Chat.group, .equal, false).all(),
                                try user!.chats.query(on: request).filter(\Chat.group, .equal, false).all()) { chats_1, chats_2 in

                                    try chats_1.forEach { chat in
                                        if chats_2.contains(where: { $0.id == chat.id }) {
                                            if chat.last_message != nil {
                                                throw Abort.notFound
                                            }
                                        }
                                    }
                                    return try next.respond(to: request)
                        }
        }
    }
}
