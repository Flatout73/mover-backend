import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let databaseURL = Environment.get("DATABASE_URL") {
        let postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        var config = TLSConfiguration.makeClientConfiguration()
        config.certificateVerification = .none
        var postgresConfig = try SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vexa",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_vexa_password",
            database: Environment.get("DATABASE_NAME") ?? "mover",
            tls: .prefer(.init(configuration: config)))
        //postgresConfig.coreConfiguration.tls.sslContext = .init(configuration: .makeClientConfiguration())
        //postgresConfig.coreConfiguration.tls = .disable
        //postgresConfig.coreConfiguration.tls.certificateVerification = .none
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

    }

    app.views.use(.leaf)

    app.migrations.add(CreateUser(), CreateOrder(), CreateTrip())

    let user = User(id: UUID(uuidString: "669C7011-E716-492D-80AF-ADBECDAADBA1"), firstName: "Test", lastName: "Test",
                    email: "leonid173m@gmail.com", password: "123456", emailVerified: .google)

    Task {
        //if app.environment == .development {
        try! await app.autoMigrate().get()
            //try app.queues.startInProcessJobs()
        //}
        try? await user.save(on: app.db)
    }

    // register routes
    try routes(app)
}
