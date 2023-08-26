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
        let auth = routes
            .grouped("orders")

        auth
            .get(use: orders)
        auth
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .put("create", use: createOrder)
    }

    func orders(req: Request) async throws -> [Order] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return try await Order
                .query(on: req.db)
                .sort(\.$untilDate)
                .all()
        }

        let orders = try await Order
            .query(on: req.db)
            .join(User.self, on: \Order.$user.$id == \User.$id)
            .group(.or, { group in
                group.filter(\Order.$origin ~~ query)
                    .filter(\Order.$destination ~~ query)
                    .filter(DatabaseQuery.Field.path(["contactType"], schema: "orders"), .custom("ilike"), DatabaseQuery.Value.custom("%\(query)%"))
                    .filter(\Order.$notes ~~ query)
                    .filter(User.self, \User.$firstName ~~ query)
                    .filter(User.self, \User.$lastName ~~ query)
                    .filter(User.self, \User.$email ~~ query)

                if let category = BindleShared.Category(rawValue: query) {
                    group
                        .filter(\Order.$category == (category))
                }
            })
            .all()
        

        return orders
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
}
