//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import Vapor
import Fluent
import BindleShared


final class Trip: Model, Content {
    static let schema = "trips"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .date)
    var date: Date

    @Field(key: .bagType)
    var bagType: [BagType]

    @Field(key: .bagTypeCost)
    var bagTypeCost: [BagType]

    @Field(key: .contactType)
    var contactType: ContactType

    @Field(key: .contactPhone)
    var contactPhone: String?

    @OptionalField(key: .meetingPoint)
    var meetingPoint: String?

    @OptionalField(key: .notes)
    var notes: String?

    @Parent(key: .user)
    var user: User

    @Children(for: \CityPoint.$trip)
    var path: [CityPoint]


    init() { }

    init(id: UUID? = nil, date: Date, bagType: [BagType],
         bagTypeCost: [BagType], contactType: ContactType, contactPhone: String,
         meetingPoint: String? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.bagType = bagType
        self.bagTypeCost = bagTypeCost
        self.contactType = contactType
        self.contactPhone = contactPhone
        self.meetingPoint = meetingPoint
        self.notes = notes
    }
}

extension FieldKey {
    static let destination: FieldKey = "destination"
    static let bagType: FieldKey = "bagType"
    static let bagTypeCost: FieldKey = "bagTypeCost"
    static let contactPhone: FieldKey = "contactPhone"
    static let notes: FieldKey = "notes"
    static let user: FieldKey = "user"
    static let date: FieldKey = "date"
    static let meetingPoint: FieldKey = "meetingPoint"
    static let contactType: FieldKey = "contactType"
}

extension Trip: Hashable {
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
