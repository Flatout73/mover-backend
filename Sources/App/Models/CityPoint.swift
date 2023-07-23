//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 23.07.2023.
//

import Fluent
import Vapor

final class CityPoint: Model, Content {
    static let schema = "cityPoints"

    @ID(key: .id)
    var id: UUID?

    @Field(key: .name)
    var name: String

    @OptionalField(key: .date)
    var date: Date?

    @Parent(key: .path)
    var trip: Trip

    init() { }
}


extension FieldKey {
    static let name: FieldKey = "name"
    static let path: FieldKey = "path"
}
