//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import Fluent
import Vapor
import BindleShared

struct OrderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let order = routes
            .grouped("orders")

        order
            .get(use: orders)

        order
            .get("filter", use: filterOrders)
        order
            .get("search", use: searchOrders)

        order
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .put("create", use: createOrder)

        order
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .post("edit", use: editOrder)

        order
            .group(":orderID") { group in
                group
                    .grouped(UserAuthenticator())
                    .grouped(User.guardMiddleware())
                    .delete(use: delete)

                group
                    .get(use: fetchOrder)
            }
    }

    func orders(req: Request) async throws -> Page<OrderResponse> {
        return try await Order
            .query(on: req.db)
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .sort(\.$untilDate, .descending)
            .paginate(for: req)
            .map({
                try OrderResponse(order: $0)
            })
    }

    func searchOrders(req: Request) async throws -> [OrderResponse] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return []
        }

        let orders = try await Order
            .query(on: req.db)
            .join(User.self, on: \Order.$user.$id == \User.$id)
            .group(.or, { group in
                group.filter(\Order.$origin ~~ query)
                    .filter(\Order.$destination ~~ query)
                    //.filter(DatabaseQuery.Field.path(["contactType"], schema: "orders"), .custom("ilike"), DatabaseQuery.Value.custom("'%\(query)%'"))
                    .filter(\Order.$notes ~~ query)
                    .filter(User.self, \User.$firstName ~~ query)
                    .filter(User.self, \User.$lastName ~~ query)
                    .filter(User.self, \User.$email ~~ query)

                if let category = BindleShared.Category(rawValue: query) {
                    group
                        .filter(\Order.$category == (category))
                }
            })
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .all()
            .map({
                try OrderResponse(order: $0)
            })
        

        return orders
    }

    func filterOrders(req: Request) async throws -> OrderFilterResult {
        let origin = try? req.query.get(String.self, at: "origin")
        let destination = try? req.query.get(String.self, at: "destination")

        print("Filter orders", origin, destination)

        let allOrders = try await Order
            .query(on: req.db)
            .filter(\Order.$untilDate >= Date())
            .group(.or, { group in
                if let origin {
                    group
                        .filter(\Order.$origin, .custom("ilike"), "%\(origin)%")
                }

                if let destination {
                    group
                        .filter(\Order.$destination, .custom("ilike"), "%\(destination)%")
                }
            })
            .sort(\.$untilDate)
            .unique()
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .all()

        var similarOrders: [OrderResponse] = []
        var orders: [OrderResponse] = []

        if let origin = origin?.lowercased(), let destination = destination?.lowercased() {
            for order in allOrders {
                if order.destination.lowercased().contains(destination) &&
                    order.origin.lowercased().contains(origin) {
                    try orders.append(OrderResponse(order: order))
                } else {
                    try similarOrders.append(OrderResponse(order: order))
                }
            }
        } else {
            try orders = allOrders.map({ try OrderResponse(order: $0) })
        }

        return OrderFilterResult(orders: orders, similarOrders: similarOrders)
    }

    func createOrder(req: Request) async throws -> Order {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let body = try req.content.decode(OrderRequestBody.self)

        let order = Order(origin: body.origin, destination: body.destination,
                          category: body.category,
                          contactType: body.contactType,
                          untilDate: body.untilDate, notes: body.notes)

        order.$user.id = try user.requireID()
        try await order.save(on: req.db)
        
        return order
    }

    func editOrder(req: Request) async throws -> Order {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let body = try req.content.decode(OrderRequestBody.self)

        try await user.$orders.load(on: req.db)

        guard let order = user.orders.first(where: { $0.id?.uuidString == body.id }) else {
            throw Abort(.notFound)
        }

        print("Edit order", order)

        order.untilDate = body.untilDate
        order.category = body.category
        order.contactType = body.contactType
        order.notes = body.notes

        order.origin = body.origin
        order.destination = body.destination

        try await order.save(on: req.db)

        return order
    }

    func fetchOrder(req: Request) async throws -> OrderResponse {
        guard let order = try await Order.find(req.parameters.get("orderID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await order.$user.load(on: req.db)
        try await order.user.$ratings.load(on: req.db)

        return try OrderResponse(order: order)
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let orderID = req.parameters.get("orderID") else {
            throw Abort(.notFound)
        }
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        try await user.$orders.load(on: req.db)

        guard let order = user.orders.first(where: { $0.id?.uuidString == orderID }) else {
            throw Abort(.notFound)
        }
        print("Deleting trip with id: \(orderID)")

        try await order.delete(on: req.db)

        return .ok
    }
}
