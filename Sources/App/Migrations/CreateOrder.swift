//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation

import Fluent

struct CreateOrder: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("orders")
            .id()
            .field(.origin, .string, .required)
            .field(.destination, .string, .required)
            .field(.category, .string, .required)
            .field(.untilDate, .datetime)
            .field(.notes, .string)
            .field(.contactType, .dictionary(of: .string))
            .field(.createdAt, .datetime)
            .field(.updatedAt, .datetime)
            .field(.deletedAt, .datetime)
            .field(.user, .uuid, .references("users", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("orders").delete()
    }
}
