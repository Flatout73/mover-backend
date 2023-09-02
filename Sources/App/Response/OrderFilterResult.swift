//
//  OrderFilterResult.swift
//  
//
//  Created by Leonid Lyadveykin on 02.09.2023.
//

import Foundation
import Vapor

struct OrderFilterResult: Content {
    let orders: [OrderResponse]
    let similarOrders: [OrderResponse]
}
