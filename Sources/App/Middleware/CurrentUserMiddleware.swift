//
//  CurrentUserMiddleware.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor

final class CurrentUserMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let id = request.http.headers.firstValue(name: .init("id")) ?? ""
        let token = request.http.headers.firstValue(name: .init("token"))
        
        return User.query(on: request).group(.and) { and in
            and.filter(\User.id, .equal, UUID(id))
            and.filter(\User.token, .equal, token)
            and.filter(\User.authorized, .equal, true)
            and.filter(\User.logged, .equal, true)
        }.first().flatMap(to: Response.self) { user in
            guard user != nil else { throw Abort.notLogged }
            return try next.respond(to: request)
        }
    }
}
