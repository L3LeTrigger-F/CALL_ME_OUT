//
//  Item.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/16.
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
