//
//  Message+Class.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import FluentSQLite

extension Message: Content {}
extension Message: Parameter {}

// MARK: Add reference to User and Chat
extension Message: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.senderID, to: \User.id)
            builder.reference(from: \.chatID, to: \Chat.id)
        }
    }
}

// MARK: Validations
extension Message: Validatable {
    static func validations() throws -> Validations<Message> {
        var validations = Validations(Message.self)
        try validations.add(\.text, .count(1...))
        return validations
    }
}
