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
    var msg: String
    
    init(msg: String) {
        self.msg = msg
    }
}
