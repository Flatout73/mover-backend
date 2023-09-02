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
            .field(.bagType, .dictionary(of: .int), .required)
            .field(.notes, .string)
            .field(.date, .datetime)
            .field(.meetingPoint, .string)
            .field(.contactType, .dictionary(of: .string))
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .field(.user, .uuid, .references("users", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("trips").delete()
    }
}
