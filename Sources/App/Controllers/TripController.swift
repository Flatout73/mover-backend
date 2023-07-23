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
            .get("filter", use: filterTrips)
        trip
            .get("search", use: searchTrips)
        trip
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .put("create", use: createTrip)

        trip
            .grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())
            .post("edit", use: editTrip)
    }

    func searchTrips(req: Request) async throws -> [Trip] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return try await trips(req: req).items
        }

        print("Search trips", query)
        let trips = try await Trip
            .query(on: req.db)
            .join(User.self, on: \Trip.$user.$id == \User.$id)
            .join(CityPoint.self, on: \Trip.$id == \CityPoint.$trip.$id)
            .group(.or, { group in
                group
                    .filter(\Trip.$contactPhone ~~ query)
                    .filter(\Trip.$notes, .custom("ilike"), "%\(query)%")
                    .filter(DatabaseQuery.Field.path(["bagType"], schema: "trips"), .custom("&&"), DatabaseQuery.Value.custom("'{\"\(query)\"}'"))
                    .filter(DatabaseQuery.Field.path(["bagTypeCost"], schema: "trips"), .custom("&&"), DatabaseQuery.Value.custom("'{\"\(query)\"}'"))
                    .filter(User.self, \User.$firstName, .custom("ilike"), "%\(query)%")
                    .filter(User.self, \User.$lastName, .custom("ilike"), "%\(query)%")
                    .filter(User.self, \User.$email, .custom("ilike"), "%\(query)%")
                    .filter(CityPoint.self, \CityPoint.$name, .custom("ilike"), "%\(query)%")
            })
            .with(\.$path)
            .sort(\.$date)
            .all()


        return trips
    }

    func filterTrips(req: Request) async throws -> [Trip] {
        let origin = try? req.query.get(String.self, at: "origin")
        let destination = try? req.query.get(String.self, at: "destination")

        print("Filter trips", origin, destination)
        var trips = try await Trip
            .query(on: req.db)
            .join(CityPoint.self, on: \CityPoint.$trip.$id == \Trip.$id)
            .group(.or, { group in
                if let origin {
                    group
                        .filter(CityPoint.self, \CityPoint.$name, .custom("ilike"), "%\(origin)%")
                }

                if let destination {
                    group
                        .filter(CityPoint.self, \CityPoint.$name, .custom("ilike"), "%\(destination)%")
                }
            })
            .with(\.$path)
            .sort(\.$date)
            .all()

        return trips.filter({
            let originIndex = $0.path.firstIndex(where: { $0.name == origin }) ?? 0
            let lastIndex = $0.path.lastIndex(where: { $0.name == destination }) ?? $0.path.count

            return lastIndex > originIndex
        })
    }

    func trips(req: Request) async throws -> Page<Trip> {
        return try await Trip
            .query(on: req.db)
            .with(\.$path)
            .sort(\.$date)
            .paginate(for: req)
    }

    func createTrip(req: Request) async throws -> Trip {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        print("Trip creation for user", user)

        let body = try req.content.decode(TripRequestBody.self)

        let path = body.path.map { point in
            let cityPoint = CityPoint()
            cityPoint.name = point.name
            cityPoint.date = point.date
            return cityPoint
        }
        
        let trip = Trip(date: body.date, bagType: Array(body.bagType),
                        bagTypeCost: Array(body.bagTypeCost), contactType: body.contactType,
                        contactPhone: body.contactPhone, meetingPoint: body.meetingPoint, notes: body.notes)

        trip.$user.id = try user.requireID()

        try await trip.save(on: req.db)

        try await trip.$path.create(path, on: req.db)
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
        trip.bagType = Array(body.bagType)
        trip.bagTypeCost = Array(body.bagTypeCost)
        trip.contactType =  body.contactType
        trip.contactPhone = body.contactPhone
        trip.meetingPoint = body.meetingPoint
        trip.notes = body.notes

        let path = body.path.map { point in
            let cityPoint = CityPoint()
            cityPoint.name = point.name
            cityPoint.date = point.date
            return cityPoint
        }

        try await trip.save(on: req.db)
        try await trip.$path.create(path, on: req.db)
        
        return trip
    }
}
