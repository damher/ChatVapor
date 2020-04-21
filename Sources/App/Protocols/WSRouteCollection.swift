//
//  WSRouteCollection.swift
//  App
//
//  Created by Mher Davtyan on 2/18/20.
//

import Vapor

public protocol WSRouteCollection {
    func boot(router: NIOWebSocketServer) throws
}

extension NIOWebSocketServer {
    public func register(collection: WSRouteCollection) throws {
        try collection.boot(router: self)
    }
}
