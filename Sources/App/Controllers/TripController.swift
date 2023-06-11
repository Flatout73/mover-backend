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

struct TripController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let trip = routes
            .grouped("trips")

        trip
            .get(use: trips)
        trip
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
                    .filter(DatabaseQuery.Field.path(["bagType"], schema: "trips"), .custom("&&"), DatabaseQuery.Value.custom("'{\"\(query)\"}'"))
                    .filter(DatabaseQuery.Field.path(["bagTypeCost"], schema: "trips"), .custom("&&"), DatabaseQuery.Value.custom("'{\"\(query)\"}'"))
                    .filter(User.self, \User.$firstName ~~ query)
                    .filter(User.self, \User.$lastName ~~ query)
                    .filter(User.self, \User.$email ~~ query)
            })
            .all()


        return orders
    }

    func createTrip(req: Request) async throws -> Trip {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let body = try req.content.decode(TripRequestBody.self)
        
        let trip = Trip(date: body.date, destination: body.destination, bagType: [body.bagType],
                        bagTypeCost: [body.bagTypeCost], contactType: body.contactType,
                        contactPhone: body.contactPhone, meetingPoint: body.meetingPoint, notes: body.notes,
                        user: user)

        try await trip.save(on: req.db)
        return trip
    }
}
