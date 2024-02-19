import Foundation

extension CoreAPI {
	public enum TransactionMessageType: String, Codable, CaseIterable {
		case plaintext = "Plaintext"
		case encrypted = "Encrypted"
	}
}
