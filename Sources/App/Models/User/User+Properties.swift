//
//  User+Properties.swift
//  App
//
//  Created by Mher Davtyan on 2/17/20.
//

import Vapor
import FluentSQLite
import Crypto

final class User: SQLiteUUIDModel {
    
    var id: UUID?
    var name: String
    var email: String
    var password: String
    var token: String?
    var authorized: Bool?
    var logged: Bool?
    var image: Data?
    var created: Date?
    var uncheckedChats: [UUID: Int64]?
    
    // MARK: - Relationships
    /// `Message`
    var messages: Children<User, Message> {
        return children(\.senderID)
    }

    /// `Chat`
    var chats: Siblings<User, Chat, UserChatPivot> {
        return siblings()
    }
}

// MARK: - Public
extension User {
    final class Public: SQLiteUUIDModel, Content {
        
        var id: UUID?
        var name: String
        var email: String
        var token: String?
        var logged: Bool?
        var image: Data?
        
        init(id: UUID?, name: String, email: String, image: Data?, token: String?, logged: Bool?) {
            self.id = id
            self.name = name
            self.email = email
            self.image = image
            self.token = token
            self.logged = logged
        }
    }
}
