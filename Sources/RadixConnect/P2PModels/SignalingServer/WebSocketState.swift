import Foundation

// MARK: - WebSocketState
/// The state of websocket
public enum WebSocketState: Sendable, Hashable, CustomStringConvertible {
	case new
	case connecting
	case open
	case closing
	case closed(URLSessionWebSocketTask.CloseCode)
}

extension WebSocketState {
	public var description: String {
		switch self {
		case .new: return "new"
		case .connecting: return "connecting"
		case .open: return "open"
		case .closing: return "Closing"
		case let .closed(closeCode): return "Closed(code: \(String(describing: closeCode))"
		}
	}
}

// MARK: - URLSessionWebSocketTask.CloseCode + CustomStringConvertible
extension URLSessionWebSocketTask.CloseCode: CustomStringConvertible {
	public var description: String {
		switch self {
		case .abnormalClosure:
			return "abnormalClosure"
		case .invalid:
			return "invalid"
		case .normalClosure:
			return "normalClosure"
		case .goingAway:
			return "goingAway"
		case .protocolError:
			return "protocolError"
		case .unsupportedData:
			return "unsupportedData"
		case .noStatusReceived:
			return "noStatusReceived"
		case .invalidFramePayloadData:
			return "invalidFramePayloadData"
		case .policyViolation:
			return "policyViolation"
		case .messageTooBig:
			return "messageTooBig"
		case .mandatoryExtensionMissing:
			return "mandatoryExtensionMissing"
		case .internalServerError:
			return "internalServerError"
		case .tlsHandshakeFailure:
			return "tlsHandshakeFailure"
		@unknown default:
			return "Unknown \(String(describing: rawValue))"
		}
	}
}

// MARK: - URLSessionTask.State + CustomStringConvertible
extension URLSessionTask.State: CustomStringConvertible {
	public var description: String {
		switch self {
		case .canceling:
			return "canceling"
		case .running:
			return "running"
		case .suspended:
			return "suspended"
		case .completed:
			return "completed"
		@unknown default:
			return "Unknown \(String(describing: rawValue))"
		}
	}
}
