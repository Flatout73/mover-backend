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
    }

    func searchTrips(req: Request) async throws -> [Trip] {
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

    func filterTrips(req: Request) async throws -> TripFilterResult {
        let origin = try? req.query.get(String.self, at: "origin")
        let destination = try? req.query.get(String.self, at: "destination")

        print("Filter trips", origin, destination)

        let trips = try await Trip
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
            .all()


        if let origin = origin?.lowercased(), let destination = destination?.lowercased() {
            var newTrips: [Trip] = []
            var sameOneCityTrips: [Trip] = []

            for (i, trip) in trips.enumerated() {
                if i != trips.lastIndex(of: trip) { // если больше одного вхождения трипа
                    // если destination идет после origin
                    if (trip.path.firstIndex(where: { $0.name.lowercased().contains(origin) }) ?? 0) < (trip.path.firstIndex(where: { $0.name.lowercased().contains(destination) }) ?? trip.path.count) {
                        newTrips.append(trip)
                    }
                // если последняя точка не равна origin, а первая не равна destination
                } else if trip.path.last?.name.lowercased().contains(origin) == false, trip.path.first?.name.lowercased().contains(destination) == false {
                    sameOneCityTrips.append(trip)
                }
            }

            return TripFilterResult(trips: newTrips, similarTrips: sameOneCityTrips)
        } else {
            return TripFilterResult(trips: trips, similarTrips: [])
        }
    }

    func trips(req: Request) async throws -> Page<Trip> {
        return try await Trip
            .query(on: req.db)
            .with(\.$path)
            .sort(\.$date, .descending)
            .paginate(for: req)
    }

    func createTrip(req: Request) async throws -> Trip {
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }
        print("Trip creation for user", user)

        let string = req.body.data!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sts = TripRequestBody(id: "2131", date: Date(), path: [],
                        contactPhone: "", bagType: .init(), bagTypeCost: [.hand: 123], contactType: .telegram)
        print(String(data: try JSONEncoder().encode(sts), encoding: .utf8))
        let body = try decoder.decode(TripRequestBody.self, from: string)
//        let body = try req.content
//            .decode(, as: .json)



        let path = body.path.map { point in
            let cityPoint = CityPoint()
            cityPoint.name = point.name
            cityPoint.date = point.date
            return cityPoint
        }
        
        let trip = Trip(date: body.date, bagType: Array(body.bagType),
                        bagTypeCost: body.bagTypeCost, contactType: body.contactType,
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
        trip.bagTypeCost = body.bagTypeCost
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
