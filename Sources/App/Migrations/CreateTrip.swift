//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import Fluent

struct CreateTrip: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("trips")
            .id()
            .field(.destination, .string)
            .field(.bagType, .array(of: .string))
            .field(.bagTypeCost, .array(of: .string), .required)
            .field(.contactPhone, .string)
            .field(.notes, .string)
            .field(.date, .date)
            .field(.meetingPoint, .string)
            .field(.contactType, .string)
            .field(.user, .uuid, .references("users", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("trips").delete()
    }
}
