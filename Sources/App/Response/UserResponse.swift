//
//  UserResponse.swift
//  
//
//  Created by Leonid Lyadveykin on 04.08.2023.
//

import Vapor
import BindleShared

struct UserResponse: Content, Equatable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let rating: Float?
    let email: String
    let phone: String?
    let contactType: Set<ContactType>
    let imageURL: String?

    init(user: User) throws {
        let rating = Float(user.ratings.reduce(0, { $0 + $1.rating })) / Float(user.ratings.count)

        self.id = try user.requireID()
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.rating = rating.isNaN ? nil : rating
        self.email = user.email
        self.phone = user.phone
        self.imageURL = user.imageURL
        self.contactType = Set(user.contactType)
    }
}
