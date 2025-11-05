//
//  Item.swift
//  JARVIS GPT
//
//  Created by Jamison A Lerner on 10/27/25.
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
