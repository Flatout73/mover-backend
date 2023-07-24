//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 23.07.2023.
//

import Vapor
import Fluent

struct CreateCityPoint: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("cityPoints")
            .id()
            .field(.name, .string, .required)
            .field(.date, .date)
            .field(.trip, .uuid, .references("trips", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("cityPoints").delete()
    }
}
