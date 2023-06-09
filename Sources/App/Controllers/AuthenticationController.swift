//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation

import Fluent
import Vapor

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("apple", use: apple)
    }

    func apple(req: Request) async throws -> User {

        let password = UUID().uuidString
        let user = User()
        user.password = password

        try await user.save(on: req.db)

        return user
    }
}
