//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Vapor
import Fluent

enum Category: String, Codable {
    case documents
    case packages
    case other
}


final class Order: Model, Content {
    static let schema = "orders"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .origin)
    var origin: String

    @Field(key: .destination)
    var destination: String

    @Field(key: .category)
    var category: Category

    @OptionalField(key: .untilDate)
    var untilDate: Date?

    @OptionalField(key: .contactPhone)
    var contactPhone: String?

    @OptionalField(key: .notes)
    var notes: String?

    @Parent(key: .user)
    var user: User

    
    init() { }
}

extension FieldKey {
    static let origin: FieldKey = "origin"
    static let category: FieldKey = "category"
    static let untilDate: FieldKey = "untilDate"
}
