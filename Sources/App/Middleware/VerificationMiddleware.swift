//
//  QueryMiddleware.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor

final class VerificationMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let token = request.query[String.self, at: "token"]
        
        return User.query(on: request)
            .filter(\User.token, .equal, token)
            .first().flatMap(to: Response.self) { user in
                if user == nil { throw Abort.notVerificated }
                return try next.respond(to: request)
        }
    }
}
