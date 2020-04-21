//
//  Chat+Properties.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor
import FluentSQLite

final class Chat: SQLiteUUIDModel {
    
    var id: UUID?
    var name: String?
    var members: [User]?
    var group: Bool?
    var last_message: Message?
    var unread_count: Int64?
    var created: Date?
    
    // MARK: - Relationships
    /// `Message`
    var messages: Children<Chat, Message> {
        return children(\.chatID)
    }
    
    /// `User`
    var users: Siblings<Chat, User, UserChatPivot> {
        return siblings()
    }
}
