//
//  UserChatPivot.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import FluentSQLite

final class UserChatPivot: SQLiteUUIDModel {
  
    var id: UUID?
  
    var userID: User.ID
    var chatID: Chat.ID

    typealias Left = User
    typealias Right = Chat
  
    static let leftIDKey: LeftIDKey = \.userID
    static let rightIDKey: RightIDKey = \.chatID

    init(_ user: User, _ chat: Chat) throws {
        self.userID = try user.requireID()
        self.chatID = try chat.requireID()
    }
}

// MARK: Reference between User and Chat
extension UserChatPivot: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id, onDelete: .cascade)
            builder.reference(from: \.chatID, to: \Chat.id, onDelete: .cascade)
        }
    }
}

extension UserChatPivot: ModifiablePivot {}
