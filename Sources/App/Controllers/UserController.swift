import Fluent
import Vapor

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
//        todos.group(":todoID") { todo in
//            todo.delete(use: delete)
//        }
    }

    func me(req: Request) async throws -> User {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        return user
    }

    func orders(req: Request) async throws -> [Order] {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        try await user.$orders.load(on: req.db)

        return user.orders
    }

    func trips(req: Request) async throws -> [Trip] {
        guard req.auth.has(User.self), let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        try await user.$trips.load(on: req.db)

        return user.trips
    }

    func logout(req: Request) async throws -> String {
        guard req.auth.has(User.self) else {
            throw Abort(.unauthorized)
        }

        let user = req.auth.get(User.self)
        user?.password = nil
        try await user?.save(on: req.db)

        return "OK"
    }

//    func delete(req: Request) async throws -> HTTPStatus {
//        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        try await todo.delete(on: req.db)
//        return .noContent
//    }
}
