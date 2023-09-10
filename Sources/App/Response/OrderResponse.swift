//
//  OrderResponse.swift
//  
//
//  Created by Leonid Lyadveykin on 02.09.2023.
//

import Vapor
import BindleShared

struct OrderResponse: Content, Equatable {
    let id: UUID
    let untilDate: Date?
    let contactType: ContactType
    let category: BindleShared.Category
    let notes: String?
    let meetingPoint: String?
    let origin: String
    let destination: String

    let user: UserResponse

    init(order: Order) throws {
        self.id = try order.requireID()
        self.untilDate = order.untilDate
        self.contactType = order.contactType
        self.category = order.category
        self.notes = order.notes
        self.origin = order.origin
        self.destination = order.destination
        self.meetingPoint = order.meetingPoint

        self.user = try UserResponse(user: order.user)
    }
}
