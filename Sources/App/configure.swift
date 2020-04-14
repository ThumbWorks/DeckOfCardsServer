import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(LeafProvider())
    try services.register(FluentPostgreSQLProvider())
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(FileMiddleware.self)
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

    // Configure a PostgreSQL database

    let pgConfig = PostgreSQLDatabaseConfig(hostname: "localhost",
                                            port: 5432,
                                            username: "roderic",
                                            database: "deleteme1",
                                            password: nil, transport: .cleartext)
    let pgDatabase = PostgreSQLDatabase(config: pgConfig)
    
    var databases = DatabasesConfig()
    databases.enableLogging(on: .psql)
    databases.add(database: pgDatabase, as: .psql)
    services.register(databases)

    try services.register(AuthenticationProvider())

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserToken.self, database: .psql)
    migrations.add(model: Trigger.self, database: .psql)
    services.register(migrations)
}
