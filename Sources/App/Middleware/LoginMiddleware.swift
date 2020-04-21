//
//  LoginMiddleware.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import Crypto

final class LoginMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        try request.content.decode([String: String].self).flatMap { data in
            User.query(on: request)
                .filter(\User.authorized, .equal, true)
                .filter(\User.email, .equal, data["email"] ?? "")
                .first().flatMap(to: Response.self) { user in
                    guard let userPassword = user?.password,
                        let receivedPassword = data["password"],
                        try BCrypt.verify(receivedPassword, created: userPassword) else {
                        throw Abort.wrongPassword
                    }
                    return try next.respond(to: request)
            }
        }
    }
}
