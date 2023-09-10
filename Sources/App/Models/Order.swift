//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Vapor
import Fluent
import BindleShared

final class Order: Model, Content {
    static let schema = "orders"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .origin)
    var origin: String

    @Field(key: .destination)
    var destination: String

    @Field(key: .category)
    var category: BindleShared.Category

    @OptionalField(key: .untilDate)
    var untilDate: Date?

    @OptionalField(key: .notes)
    var notes: String?

    @OptionalField(key: .meetingPoint)
    var meetingPoint: String?

    @Field(key: .contactType)
    var contactType: ContactType

    @Parent(key: .user)
    var user: User

    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?

    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?

    init(id: UUID? = nil, origin: String, destination: String, category: BindleShared.Category,
         contactType: ContactType, untilDate: Date? = nil, notes: String? = nil, meetingPoint: String? = nil) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.category = category
        self.untilDate = untilDate
        self.notes = notes
        self.contactType = contactType
        self.meetingPoint = meetingPoint
    }
    
    init() { }
}

extension FieldKey {
    static let origin: FieldKey = "origin"
    static let category: FieldKey = "category"
    static let untilDate: FieldKey = "untilDate"
    static let createdAt: FieldKey = "createdAt"
}
