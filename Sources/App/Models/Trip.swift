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
    var bagType: BagTypeCost

    @Field(key: .contactType)
    var contactType: ContactType

    @OptionalField(key: .meetingPoint)
    var meetingPoint: String?

    @OptionalField(key: .notes)
    var notes: String?

    @Parent(key: .user)
    var user: User

    @Children(for: \CityPoint.$trip)
    var path: [CityPoint]

    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?

    init() { }

    init(id: UUID? = nil, date: Date, bagType: BagTypeCost,
         contactType: ContactType,
         meetingPoint: String? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.bagType = bagType
        self.contactType = contactType
        self.meetingPoint = meetingPoint
        self.notes = notes
    }
}

extension FieldKey {
    static let destination: FieldKey = "destination"
    static let bagType: FieldKey = "bagType"
    static let notes: FieldKey = "notes"
    static let user: FieldKey = "user"
    static let date: FieldKey = "date"
    static let meetingPoint: FieldKey = "meetingPoint"
    static let contactType: FieldKey = "contactType"

    static let deletedAt: FieldKey = "deletedAt"
}
