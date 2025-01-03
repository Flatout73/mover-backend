import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Leaf
import BindleShared

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
        let postgresConfig = try SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vexa",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_vexa_password",
            database: Environment.get("DATABASE_NAME") ?? "mover",
            tls: .prefer(.init(configuration: config)))
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    }

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)

    app.views.use(.leaf)

    app.migrations.add(CreateUser(), CreateOrder(), CreateTrip(), CreateCityPoint(), CreateRating())

    let user = User(id: UUID(uuidString: "669C7011-E716-492D-80AF-ADBECDAADBA1"),
                    firstName: "Test", lastName: "Test",
                    email: "leonid173m@gmail.com",
                    contactType: ContactType(telegram: "flatout97", mobile: "+79123123"), password: "123456",
                    emailVerified: .google)
    user.imageURL = "https://sun6-23.userapi.com/impg/m3ied5PgFvYfeS1HskUKce-IOl0l3rK5ZdAh5A/50oYHt4zvjg.jpg?size=1024x734&quality=96&sign=118d582edf2454670748318ca1362a82&type=album"

    Task {
        //if app.environment == .development {
        try await app.autoMigrate().get()
            //try app.queues.startInProcessJobs()
        //}
        try? await user.save(on: app.db)
    }

    // register routes
    try routes(app)
}
