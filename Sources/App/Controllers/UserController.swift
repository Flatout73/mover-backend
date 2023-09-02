import Fluent
import Vapor
import BindleShared

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes
            .grouped("users")
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
        users.get("me", use: me)
        users.get("orders", use: orders)
        users.get("trips", use: trips)
        users.post("logout", use: logout)

        users.put("rating", use: rating)

        users.post("contact", use: updateContact)
    }

    func me(req: Request) async throws -> UserResponse {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        try await user.$ratings.load(on: req.db)

        return try UserResponse(user: user)
    }

    func orders(req: Request) async throws -> [OrderResponse] {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }


        return try await Order
            .query(on: req.db)
            .join(User.self, on: \Order.$user.$id == \User.$id)
            .filter(User.self, \User.$id == user.requireID())
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .sort(\.$untilDate, .descending)
            .all()
            .map({
                return try OrderResponse(order: $0)
            })
    }

    func trips(req: Request) async throws -> [TripResponse] {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        return try await Trip
            .query(on: req.db)
            .join(User.self, on: \Trip.$user.$id == \User.$id)
            .filter(User.self, \User.$id == user.requireID())
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .with(\.$path)
            .sort(\.$date, .descending)
            .all()
            .map({ trip in
                return try TripResponse(trip: trip)
            })
    }

    func logout(req: Request) async throws -> HTTPStatus {
        guard req.auth.has(User.self) else {
            throw Abort(.unauthorized)
        }

        let user = req.auth.get(User.self)
        user?.password = nil
        try await user?.save(on: req.db)

        return .ok
    }

    func rating(req: Request) async throws -> HTTPStatus {
        guard req.auth.has(User.self) else {
            throw Abort(.unauthorized)
        }

        let body = try req.content.decode(RatingRequestBody.self)

        guard let userTo = UUID(body.userIDTo),
              let user = req.auth.get(User.self) else {
            throw Abort(.notFound)
        }

        let oldRating = try await Rating
            .query(on: req.db)
            .join(User.self, on: \Rating.$userTo.$id == \User.$id)
            .filter(User.self, \.$id == userTo)
            .filter(\Rating.$updatedAt >= Date(timeIntervalSinceNow: -24 * 60 * 60))
            .count()

        guard oldRating < 1 else {
            throw Abort(.tooManyRequests)
        }

        let rating = Rating()
        rating.$userFrom.id = try user.requireID()
        rating.$userTo.id = userTo
        rating.rating = body.rating
        rating.comment = body.comment

        try await rating.save(on: req.db)

        return .ok
    }

    func updateContact(req: Request) async throws -> UserResponse {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        let body = try req.content.decode(ContactType.self)
        user.contactType = body
        print("Updaing contact types: \(body)")
        try await user.save(on: req.db)

        try await user.$ratings.load(on: req.db)
        return try UserResponse(user: user)
    }
}
