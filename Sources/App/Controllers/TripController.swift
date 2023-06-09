//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import Fluent
import Vapor

struct TripController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes
            .grouped("trips")

        auth
            .get(use: trips)
        auth
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .post("create", use: createTrip)
    }

    func trips(req: Request) async throws -> [Trip] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return try await Trip
                .query(on: req.db)
                .sort(\.$date)
                .all()
        }

        let orders = try await Trip
            .query(on: req.db)
            .join(User.self, on: \Trip.$user.$id == \Trip.$id)
            .group(.or, { group in
                group.filter(\Trip.$destination ~~ query)
                    .filter(\Trip.$contactPhone ~~ query)
                    .filter(\Trip.$notes ~~ query)
                    .filter(User.self, \User.$firstName ~~ query)
                    .filter(User.self, \User.$lastName ~~ query)
                    .filter(User.self, \User.$email ~~ query)

                if let type = BagType(rawValue: query) {
                    group
                        .filter(\Trip.$bagType == (type))
                        .filter(\Trip.$bagTypeCost == (type))
                }
            })
            .all()


        return orders
    }

    func createTrip(req: Request) async throws -> Trip {
        let trip = Trip()

        return trip
    }
}
