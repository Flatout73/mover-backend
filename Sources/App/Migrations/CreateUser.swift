import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field(.firstName, .string)
            .field(.lastName, .string)
            .field(.email, .string, .required)
            .field(.emailVerified, .string)
            .field(.appleIdentifier, .string)
            .field(.password, .string)
            .field(.contactType, .dictionary(of: .string))
            .field(.imageURL, .string)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
