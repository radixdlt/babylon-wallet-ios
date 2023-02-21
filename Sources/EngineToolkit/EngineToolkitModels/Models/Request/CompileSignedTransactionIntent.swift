import Foundation
public typealias CompileSignedTransactionIntentRequest = SignedTransactionIntent

// MARK: - CompileSignedTransactionIntentResponse
public struct CompileSignedTransactionIntentResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let compiledIntent: [UInt8]

	// MARK: Init

	public init(bytes compiledIntent: [UInt8]) {
		self.compiledIntent = compiledIntent
	}

	public init(hex compiledIntentHex: String) throws {
		self.compiledIntent = try [UInt8](hex: compiledIntentHex)
	}
}

extension CompileSignedTransactionIntentResponse {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case compiledIntent = "compiled_intent"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Data(compiledIntent).hex(), forKey: .compiledIntent)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(hex: try container.decode(String.self, forKey: .compiledIntent))
	}
}
