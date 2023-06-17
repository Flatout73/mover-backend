//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Foundation
import BindleShared
import Fluent
import Vapor
import JWT

struct AuthenticationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("apple", use: apple)
        auth.post("google", use: google)
    }

    func apple(req: Request) async throws -> User {
        let siwa = try req.content.decode(SIWARequestBody.self)
        let appleIdentity = try await req.jwt.apple.verify(siwa.appleIdentityToken,
                                                           applicationIdentifier: Constants.iOSAppID)
        let email = appleIdentity.email ?? siwa.email

        let existingUser: User?
        let password = UUID().uuidString
        if let email = email {
            existingUser = try await User
                .query(on: req.db)
                .filter(\User.$email == email)
                .first()
            existingUser?.password = password
        } else {
            existingUser = try await User
                .query(on: req.db)
                .filter(\User.$appleIdentifier == appleIdentity.subject.value)
                .first()
            existingUser?.password = password
        }

        let user = existingUser ?? User(firstName: siwa.givenName ?? "John",
                                        lastName: siwa.familyName ?? "Doe",
                                        email: email ?? "",
                                        appleIdentifier: appleIdentity.subject.value)
        user.emailVerified = .apple

        try await user.save(on: req.db)

        return user
    }

    func google(req: Request) async throws -> User {
        let google = try req.content.decode(GoogleRequestBody.self)
        let googleIDToken = try await req.jwt.google.verify(google.googleIdentityToken)
        let email = googleIDToken.email ?? google.email

        let existingUser: User?
        let password = UUID().uuidString
        if let email = email {
            existingUser = try await User
                .query(on: req.db)
                .filter(\User.$email == email)
                .first()
            existingUser?.password = password
        } else {
            existingUser = nil
        }

        let user = existingUser ?? User(firstName: googleIDToken.givenName ?? "John",
                                        lastName: googleIDToken.familyName ?? "Doe",
                                        email: email ?? "")
        user.emailVerified = .google
        try await user.save(on: req.db)

        return user
    }
}
