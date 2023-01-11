import Foundation
public typealias CompileSignedTransactionIntentRequest = SignedTransactionIntent

// MARK: - CompileSignedTransactionIntentResponse
public struct CompileSignedTransactionIntentResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let compiledSignedIntent: [UInt8]

	// MARK: Init

	public init(bytes compiledIntent: [UInt8]) {
		self.compiledSignedIntent = compiledIntent
	}

	public init(hex compiledIntentHex: String) throws {
		self.compiledSignedIntent = try [UInt8](hex: compiledIntentHex)
	}
}

public extension CompileSignedTransactionIntentResponse {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case compiledSignedIntent = "compiled_signed_intent"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Data(compiledSignedIntent).hex(), forKey: .compiledSignedIntent)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(hex: try container.decode(String.self, forKey: .compiledSignedIntent))
	}
}
