import Foundation
import Prelude
import Tagged

// MARK: - DataChannelIDTag
enum DataChannelIDTag {}
typealias DataChannelID = Tagged<DataChannelIDTag, Int32>
