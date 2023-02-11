import Foundation

// MARK: - ClientSource
public enum ClientSource: String, Codable, Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	case browserExtension = "extension"
	case mobileWallet = "wallet"
}

extension ClientSource {
	public var debugDescription: String {
		rawValue
	}

	public var description: String {
		switch self {
		case .browserExtension: return "Browser Extension"
		case .mobileWallet: return "Mobile Wallet"
		}
	}
}
