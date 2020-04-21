//
//  Abort+ChatVapor.swift
//  App
//
//  Created by Mher Davtyan on 3/13/20.
//

import Vapor

extension Abort {
    static let notFound = Abort(.notFound)
    static let notLogged = Abort(.init(statusCode: 410), reason: "There is not logged user")
    static let wrongParameters = Abort(.init(statusCode: 411), reason: "Wrong parameters")
    static let wrongPassword = Abort(.init(statusCode: 412), reason: "Wrong password")
    static let notVerificated = Abort(.init(statusCode: 413), reason: "Not verificated")
    static let alreadyInvited = Abort(.init(statusCode: 414), reason: "The user is already member of current chat")
}
