//
//  UserController.swift
//  App
//
//  Created by Mher Davtyan on 2/17/20.
//

import Vapor
import Crypto
import FluentSQLite

struct UserController: RouteCollection {
    
    // MARK: - Router
    func boot(router: Router) throws {
        router.post("register", use: register)
        
        /// VerificationMiddleware
        let verifyRoute = router.grouped(VerificationMiddleware())
        verifyRoute.get("verify-email", use: verification)
        
        /// LoginMiddleware
        let loginRoute = router.grouped(LoginMiddleware())
        loginRoute.put("login", use: login)
        
        /// CurrentUserMiddleware
        let currentUserRoutes = router.grouped(CurrentUserMiddleware())
        currentUserRoutes.get("users", use: all)
        currentUserRoutes.get("search", use: search)
        currentUserRoutes.put("logout", use: logout)
        currentUserRoutes.put("users", "name", use: name)
        currentUserRoutes.put("users", "change-password", use: password)
    }
    
    // MARK: - GET Requests
    /// Get all users
    private func all(_ req: Request) throws -> Future<[User.Public]> {
        try User.current(req).flatMap { user in
            User.query(on: req).filter(\.id != user.id).decode(data: User.Public.self).all()
        }
    }
    
    // Search users by name
    private func search(_ req: Request) throws -> Future<[User.Public]> {
        let term = req.query[String.self, at: "name"] ?? ""
        
        return try User.current(req).flatMap { current in
            return User.query(on: req)
                .filter(\.authorized == true)
                .filter(\.id != current.id)
                .all().map { users in
                    return users.filter { user in
                        user.name.lowercased().hasPrefix(term.lowercased())
                    }.map { $0.convertToPublic() }
            }
        }
    }
    
    /// Email verification
    private func verification(_ req: Request) throws -> Future<View> {
        let token = req.query[String.self, at: "token"]
        
        return User.query(on: req)
            .filter(\User.token == token)
            .first().flatMap { user in
                user?.updateToken()
                user?.authorized = true
                return user!.save(on: req).flatMap { _ in
                    try req.view().render("email")
                }
        }
    }
    
    // MARK: - POST Requests
    /// Create a user
    private func register(_ req: Request) throws -> Future<User.Public> {
        try req.content.decode(User.self).flatMap { user in
            try user.new(req).map { u in
                try SMTPManager.shared.sendVerificationMail(req, user: user)
                u.authorized = false
                u.created = Date()
                return u.convertToPublic()
            }
        }
    }
    
    // MARK: - PUT Requests
    /// Login user
    private func login(_ req: Request) throws -> Future<User.Public> {
        return try req.content.decode([String: String].self).flatMap { result in
            let email = result["email"]
            
            return User.query(on: req)
                .filter(\.email == email!)
                .first().flatMap { user in
                    user?.logged = true
                    return user!.save(on: req).convertToPublic()
            }
        }
    }
    
    /// Logout user
    private func logout(_ req: Request) throws -> Future<User.Public> {
        return try User.current(req).flatMap { user in
            user.logged = false
            user.updateToken()
            return user.save(on: req).convertToPublic()
        }
    }
    
    /// Update user's name
    private func name(_ req: Request) throws -> Future<User.Public> {
        return try User.current(req).flatMap { current in
            try req.content.decode([String: String].self).flatMap(to: User.Public.self) { dict in
                guard let name = dict.values.first, !name.isEmpty else { throw Abort(.notFound) }
                current.name = name
                return current.save(on: req).convertToPublic().always {
                    self.updateUserName(req, name, current: current)
                }
            }
        }
    }
    
    /// Update user's password
    private func password(_ req: Request) throws -> Future<User.Public> {
        return try User.current(req).flatMap { user in
            try req.content.decode([String: String].self).flatMap(to: User.Public.self) { dict in
                guard let new = dict.values.first else { throw Abort(.notFound) }
                user.password = try BCrypt.hash(new)
                return user.save(on: req).convertToPublic()
            }
        }
    }
}

extension UserController {
    
    func updateUserName(_ req: Request, _ name: String, current: User) {
        let _ = Chat.query(on: req).all().map() { chats in
            let chats_ = chats.filter {
                $0.members?.contains(where: { $0.id == current.id }) ?? false
            }
            
            let _ = chats_.map { chat in
                chat.members?.forEach { user in
                    if user.id == current.id {
                        user.name = name
                        let _ = chat.save(on: req)
                    }
                }
                
                if chat.last_message?.sender?.id == current.id {
                    chat.last_message?.sender?.name = name
                    let _ = chat.save(on: req)
                }
            }
        }
    }
}
