import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("tripsHtml") { req async in
        return try! await req.view.render("trip.leaf")
    }

    app.get { req async in
        return try! await req.view.render("index")
    }

    try app.register(collection: UserController())
    try app.register(collection: AuthenticationController())
    try app.register(collection: TripController())
    try app.register(collection: OrderController())
}
