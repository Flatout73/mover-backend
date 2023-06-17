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
            .put("create", use: createTrip)

        trip
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .post("edit", use: editTrip)
    }

    func trips(req: Request) async throws -> [Trip] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return try await Trip
                .query(on: req.db)
                .sort(\.$date)
                .all()
        }

        print("Search trips", query)
        let trips = try await Trip
            .query(on: req.db)
            .join(User.self, on: \Trip.$user.$id == \User.$id)
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


        return trips
    }

    func createTrip(req: Request) async throws -> Trip {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        print("Trip creation for user", user)

        let body = try req.content.decode(TripRequestBody.self)
        
        let trip = Trip(date: body.date, destination: body.destination, bagType: Array(body.bagType),
                        bagTypeCost: Array(body.bagTypeCost), contactType: body.contactType,
                        contactPhone: body.contactPhone, meetingPoint: body.meetingPoint, notes: body.notes)

        trip.$user.id = try user.requireID()

        try await trip.save(on: req.db)
        return trip
    }

    func editTrip(req: Request) async throws -> Trip {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        let body = try req.content.decode(TripRequestBody.self)
        try await user.$trips.load(on: req.db)

        guard let trip = user.trips.first(where: { $0.id?.uuidString == body.id }) else {
            throw Abort(.notFound)
        }

        print("Edit trip", trip)
        
        trip.date = body.date
        trip.destination = body.destination
        trip.bagType = Array(body.bagType)
        trip.bagTypeCost = Array(body.bagTypeCost)
        trip.contactType =  body.contactType
        trip.contactPhone = body.contactPhone
        trip.meetingPoint = body.meetingPoint
        trip.notes = body.notes

        try await trip.save(on: req.db)
        
        return trip
    }
}
