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
import SQLKit

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

        trip
            .group(":tripID") { group in
                group
                    .grouped(UserAuthenticator())
                    .grouped(User.guardMiddleware())
                    .delete(use: delete)

                group
                    .get(use: fetchTrip)
        }
    }

    func searchTrips(req: Request) async throws -> [TripResponse] {
        guard let query = try? req.query.get(String.self, at: "query") else {
            return []
        }

        print("Search trips", query)
        let trips = try await Trip
            .query(on: req.db)
            .join(User.self, on: \Trip.$user.$id == \User.$id)
            .join(CityPoint.self, on: \Trip.$id == \CityPoint.$trip.$id)
            .filter(\Trip.$date >= Date())
            .group(.or, { group in
                group
                    .filter(\Trip.$notes, .custom("ilike"), "%\(query)%")
                    //.filter(DatabaseQuery.Field.path(["contactType"], schema: "trips"), .custom("-> 'telegram' ilike"), DatabaseQuery.Value.custom("'%\(query)%'"))
                    .filter(User.self, \User.$firstName, .custom("ilike"), "%\(query)%")
                    .filter(User.self, \User.$lastName, .custom("ilike"), "%\(query)%")
                    .filter(User.self, \User.$email, .custom("ilike"), "%\(query)%")
                    .filter(CityPoint.self, \CityPoint.$name, .custom("ilike"), "%\(query)%")

                if let int = Int(query) {
                    group
                        .filter(DatabaseQuery.Field.path(["bagType"], schema: "trips"), .custom("-> 'carryOn' <="), DatabaseQuery.Value.custom("'\(int)'"))
                        .filter(DatabaseQuery.Field.path(["bagType"], schema: "trips"), .custom("-> 'baggage' <="), DatabaseQuery.Value.custom("'\(int)'"))
                        .filter(DatabaseQuery.Field.path(["bagType"], schema: "trips"), .custom("-> 'additionalBaggage' <="), DatabaseQuery.Value.custom("'\(int)'"))
                }
            })
            .with(\.$path)
            .sort(\.$date)
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .all()
            .map({
                try TripResponse(trip: $0)
            })


        return trips
    }

    func filterTrips(req: Request) async throws -> TripFilterResult {
        let origin = try? req.query.get(String.self, at: "origin")
        let destination = try? req.query.get(String.self, at: "destination")

        print("Filter trips", origin, destination)

        var trips = try await Trip
            .query(on: req.db)
            .join(CityPoint.self, on: \Trip.$id == \CityPoint.$trip.$id)
            .filter(\Trip.$date >= Date())
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
            .sort(\.$date)
            .unique()
            .with(\.$path)
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .all()
            .map({
                try TripResponse(trip: $0)
            })


        if let origin = origin?.lowercased(), let destination = destination?.lowercased() {
            var newTrips: [TripResponse] = []
            var sameOneCityTrips: [TripResponse] = []

            var i = 0
            while i < trips.count {
                let trip = trips[i]
                if let lastIndex = trips.lastIndex(of: trip), i != lastIndex { // если больше одного вхождения трипа
                    // если destination идет после origin
                    if (trip.path.firstIndex(where: { $0.name.lowercased().contains(origin) }) ?? 0) < (trip.path.firstIndex(where: { $0.name.lowercased().contains(destination) }) ?? trip.path.count) {
                        newTrips.append(trip)
                    }
                    trips.remove(at: lastIndex) // чтобы не попасть на этот трип еще раз
                    // если последняя точка не равна origin, а первая не равна destination
                } else if trip.path.last?.name.lowercased().contains(origin) == false, trip.path.first?.name.lowercased().contains(destination) == false {
                    sameOneCityTrips.append(trip)
                }
                i += 1
            }

            return TripFilterResult(trips: newTrips, similarTrips: sameOneCityTrips)
        } else {
            return TripFilterResult(trips: trips, similarTrips: [])
        }
    }

    func trips(req: Request) async throws -> Page<TripResponse> {
        return try await Trip
            .query(on: req.db)
            .with(\.$user) { user in
                user.with(\.$ratings)
            }
            .with(\.$path)
            .sort(\.$date, .descending)
            .paginate(for: req)
            .map({ trip in
                return try TripResponse(trip: trip)
            })
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
        
        let trip = Trip(date: body.date, bagType: body.bagType,
                        contactType: body.contactType,
                        meetingPoint: body.meetingPoint, notes: body.notes)

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
        trip.bagType = body.bagType
        trip.contactType = body.contactType
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

    func fetchTrip(req: Request) async throws -> Trip {
        guard let trip = try await Trip.find(req.parameters.get("tripID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return trip
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let tripID = req.parameters.get("tripID") else {
            throw Abort(.notFound)
        }
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        try await user.$trips.load(on: req.db)
        guard let trip = user.trips.first(where: { $0.id?.uuidString == tripID }) else {
            throw Abort(.notFound)
        }
        print("Deleting trip with id: \(tripID)")

        try await trip.delete(on: req.db)

        return .ok
    }
}
