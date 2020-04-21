import FluentSQLite
import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(LeafProvider())
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure database
    var databases = DatabasesConfig()
    try databases.add(database: SQLiteDatabase(storage: .file(path: "db.sqlite")), as: .sqlite)
    services.register(databases)
    
    // Register NIO websocket server
    let wss = NIOWebSocketServer.default()
    try webSocketRoutes(wss)
    services.register(wss, as: WebSocketServer.self)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(model: Chat.self, database: .sqlite)
    migrations.add(model: Message.self, database: .sqlite)
    migrations.add(model: UserChatPivot.self, database: .sqlite)
    services.register(migrations)
}
