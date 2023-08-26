//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 03.08.2023.
//

import Foundation
import Fluent

struct CreateRating: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("ratings")
            .id()
            .field(.rating, .int, .required)
            .field(.comment, .string)
            .field(.updatedAt, .datetime)
            .field(.userTo, .uuid, .references("users", "id", onDelete: .cascade))
            .field(.userFrom, .uuid, .references("users", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("ratings").delete()
    }
}
