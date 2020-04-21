//
//  User+Class.swift
//  App
//
//  Created by Mher Davtyan on 2/17/20.
//

import Vapor
import Crypto
import FluentSQLite

extension User: Content {}
extension User: Parameter {}

extension User {
    
    /// Currnt
    static func current(_ req: Request) throws -> Future<User> {
        let id = req.http.headers.firstValue(name: .init("id")) ?? ""
        return User.query(on: req).filter(\.id == UUID(id)).first().map {
            guard let user = $0 else { throw Abort(.notFound) }
            return user
        }
    }
    
    /// Configure new user
    func new(_ req: Request) throws -> Future<User> {
        try validate()
        password = try BCrypt.hash(password)
        created = Date()
        updateToken()
        return save(on: req)
    }
    
    /// Update token
    func updateToken() {
        do {
            token = try CryptoRandom().generateData(count: 30).hexEncodedString()
        } catch {
            debugPrint(error)
        }
    }
}

// MARK: - Migration
extension User: Migration {
    
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.email)
        }
    }
}

// MARK: - Validation
extension User: Validatable {
    
    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.name, .count(2...))
        try validations.add(\.password, .count(6...))
        return validations
    }
}

// MARK: - Convert User to Public
extension User {
    
    func convertToPublic() -> User.Public {
        return User.Public(id: id,
                           name: name,
                           email: email,
                           image: image,
                           token: token,
                           logged: logged)
    }
}

extension Future where T: User {
    
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}
