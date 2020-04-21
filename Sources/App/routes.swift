import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let userController = UserController()
    try router.register(collection: userController)
    
    let chatController = ChatController()
    try router.register(collection: chatController)
}

/// Register your application's WebSocket routes here.
public func webSocketRoutes(_ router: NIOWebSocketServer) throws {
    
    let wsController = WebSocketController()
    try router.register(collection: wsController)
}
