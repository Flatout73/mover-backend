//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 04.08.2023.
//

import Vapor
import BindleShared

struct TripResponse: Content, Equatable {
    static func == (lhs: TripResponse, rhs: TripResponse) -> Bool {
        return lhs.id == rhs.id
    }

    let id: UUID
    let date: Date
    let bagType: BagTypeCost
    let contactType: ContactType
    let meetingPoint: String?
    let notes: String?

    let user: UserResponse

    let path: [CityPoint]

    init(trip: Trip) throws {
        self.id = try trip.requireID()
        self.date = trip.date
        self.bagType = trip.bagType
        self.contactType = trip.contactType
        self.meetingPoint = trip.meetingPoint
        self.notes = trip.notes
        self.user = try UserResponse(user: trip.user)
        self.path = trip.path
    }
}
