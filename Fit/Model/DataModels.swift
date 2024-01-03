//
//  DataModels.swift
//  Fit
//
//  Created by mahesh lad on 20/10/2023.
//  Copyright © 2023 mahesh lad. All rights reserved.
//

import Foundation

struct Coordinate : Codable {
    var latitude: Double
    var longitude: Double
}

struct Workout : Codable {
    var startTime: Date
    var endTime : Date
    var duration : TimeInterval
    var locations : [Coordinate]
    var workoutType : String
    var totalSteps : Double
    var flightsClimbed : Double
    var distance : Double
}
