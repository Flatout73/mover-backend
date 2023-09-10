import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        return try await req.view.render("index")
    }

    try app.register(collection: UserController())
    try app.register(collection: AuthenticationController())
    try app.register(collection: TripController())
    try app.register(collection: OrderController())
}
