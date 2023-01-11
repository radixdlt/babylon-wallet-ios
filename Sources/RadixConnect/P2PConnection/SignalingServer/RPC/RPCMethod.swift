import Foundation

public enum RPCMethod: String, Codable, Sendable, Hashable, CustomStringConvertible {
	case offer
	case answer
	case iceCandidate
}
