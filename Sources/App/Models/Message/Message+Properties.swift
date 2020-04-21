//
//  Message+Properties.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import FluentSQLite

final class Message: SQLiteUUIDModel {
    
    var id: UUID?
    var text: String
    var created: Date?
    var senderID: User.ID
    var chatID: Chat.ID
    var sender: User?
    
    // MARK: - Relationships
    /// `User`
    var user: Parent<Message, User> {
        return parent(\.senderID)
    }

    /// `Chat`
    var chat: Parent<Message, Chat> {
        return parent(\.chatID)
    }
}
