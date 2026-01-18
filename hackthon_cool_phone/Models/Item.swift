import Foundation
import SwiftData
//需要解决的问题：1、如何在接听的时候调用语音大模型？
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
