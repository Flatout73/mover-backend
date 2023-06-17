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

    @Field(key: .contactPhone)
    var contactPhone: String

    @OptionalField(key: .notes)
    var notes: String?

    @OptionalField(key: .contactType)
    var contactType: ContactType?

    @Parent(key: .user)
    var user: User

    init(id: UUID? = nil, origin: String, destination: String, category: BindleShared.Category,
         contactPhone: String, untilDate: Date? = nil, notes: String? = nil,
         contactType: ContactType? = nil) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.category = category
        self.untilDate = untilDate
        self.contactPhone = contactPhone
        self.notes = notes
        self.contactType = contactType
    }
    
    init() { }
}

extension FieldKey {
    static let origin: FieldKey = "origin"
    static let category: FieldKey = "category"
    static let untilDate: FieldKey = "untilDate"
}
