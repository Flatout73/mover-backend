//
//  File.swift
//  
//
//  Created by Leonid Lyadveykin on 25.07.2023.
//

import Vapor

struct TripFilterResult: Content {
    let trips: [Trip]
    let similarTrips: [Trip]
}
