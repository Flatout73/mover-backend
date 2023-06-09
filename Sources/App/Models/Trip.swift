//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import Vapor
import Fluent

enum BagType: String, Codable {
    case hand
    case baggage
    case additionalBaggage
}

enum ContactType: String, Codable {
    case telegram
    case whatsapp
    case mobile
    case email
}

final class Trip: Model, Content {
    static let schema = "trips"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .date)
    var date: String

    @Field(key: .destination)
    var destination: String

    @Field(key: .bagType)
    var bagType: BagType

    @Field(key: .bagTypeCost)
    var bagTypeCost: BagType

    @OptionalField(key: .contactPhone)
    var contactPhone: String?

    @OptionalField(key: .meetingPoint)
    var meetingPoint: String?

    @OptionalField(key: .notes)
    var notes: String?

    @Parent(key: .user)
    var user: User


    init() { }
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
}
