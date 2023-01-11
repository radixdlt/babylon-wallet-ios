import Foundation

// MARK: - ClientSource
public enum ClientSource: String, Codable, Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	case browserExtension = "extension"
	case mobileWallet = "wallet"
}

public extension ClientSource {
	var debugDescription: String {
		rawValue
	}

	var description: String {
		switch self {
		case .browserExtension: return "Browser Extension"
		case .mobileWallet: return "Mobile Wallet"
		}
	}
}
