//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 03.08.2023.
//

import Vapor
import Fluent

final class Rating: Model, Content {
    static let schema = "ratings"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .rating)
    var rating: Int

    @OptionalField(key: .comment)
    var comment: String?

    @Parent(key: .userTo)
    var userTo: User

    @Parent(key: .userFrom)
    var userFrom: User
}

extension FieldKey {
    static let rating: FieldKey = "rating"
    static let comment: FieldKey = "comment"
    static let userTo: FieldKey = "userTo"
    static let userFrom: FieldKey = "userFrom"
}
