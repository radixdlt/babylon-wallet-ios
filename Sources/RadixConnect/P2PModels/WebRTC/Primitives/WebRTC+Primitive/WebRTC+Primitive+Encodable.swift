import Foundation

public extension WebRTCPrimitive {
	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		switch self {
		case let .offer(value):
			try singleValueContainer.encode(value)
		case let .answer(value):
			try singleValueContainer.encode(value)
		case let .iceCandidate(values):
			try singleValueContainer.encode(values)
		}
	}
}
