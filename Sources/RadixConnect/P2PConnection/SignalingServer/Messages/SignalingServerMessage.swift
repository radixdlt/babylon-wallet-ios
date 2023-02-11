import Foundation

// MARK: - SignalingServerMessage
public enum SignalingServerMessage: Sendable, Hashable {
	case incoming(Incoming)
	case outgoing(Outgoing)
}

extension SignalingServerMessage {
	public var incoming: Incoming? {
		switch self {
		case let .incoming(value): return value
		case .outgoing: return nil
		}
	}

	public var outgoing: Outgoing? {
		switch self {
		case let .outgoing(value): return value
		case .incoming: return nil
		}
	}
}
