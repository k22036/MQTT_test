//
//  Item.swift
//  MQTT_test
//
//  Created by k22036kk on 2025/05/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
