import Foundation

public enum WebRTCContinualGatheringPolicy: String, Sendable, Hashable, Codable, CustomStringConvertible {
	case gatherOnce
	case gatherContinually
}
