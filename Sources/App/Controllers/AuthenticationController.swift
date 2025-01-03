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
        if let email = email {
            existingUser = try await User
                .query(on: req.db)
                .filter(\User.$email == email)
                .first()
            //existingUser?.password = password
        } else {
            existingUser = try await User
                .query(on: req.db)
                .filter(\User.$appleIdentifier == appleIdentity.subject.value)
                .first()
            //existingUser?.password = password
        }

        print("Apple login with an existing user: ", existingUser)

        let user = existingUser ?? User(firstName: siwa.givenName,
                                        lastName: siwa.familyName,
                                        email: email ?? "",
                                        contactType: ContactType(),
                                        password: UUID().uuidString,
                                        appleIdentifier: appleIdentity.subject.value)
        user.emailVerified = .apple

        try await user.save(on: req.db)

        return user
    }

    func google(req: Request) async throws -> User {
        let google = try req.content.decode(GoogleRequestBody.self)
        let googleIDToken = try await req.jwt.google.verify(google.googleIdentityToken)
        guard let email = googleIDToken.email ?? google.email else {
            throw AuthenticationError.invalidEmailOrPassword
        }

        let existingUser = try await User
            .query(on: req.db)
            .filter(\User.$email == email)
            .first()
        // existingUser?.password = password

        print("Google login with an existing user: ", existingUser)

        let user = existingUser ?? User(firstName: googleIDToken.givenName,
                                        lastName: googleIDToken.familyName,
                                        email: email,
                                        contactType: ContactType(),
                                        password: UUID().uuidString)
        user.emailVerified = .google
        user.imageURL = googleIDToken.picture
        
        try await user.save(on: req.db)

        return user
    }
}
