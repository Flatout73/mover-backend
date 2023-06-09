//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 09.06.2023.
//

import Vapor
import Fluent

struct UserAuthenticator: AsyncBasicAuthenticator {
    typealias User = App.User

    func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        let user = try await User.query(on: request.db)
            .filter(\User.$email == basic.username)
            .first()

        guard let user = user, user.password?.isEmpty == false, user.password == basic.password else {
            throw AuthenticationError.invalidEmailOrPassword
        }

        request.auth.login(user)
    }
}
