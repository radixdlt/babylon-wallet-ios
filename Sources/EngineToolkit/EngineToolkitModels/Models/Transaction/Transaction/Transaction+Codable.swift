import Foundation

extension TransactionManifest {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type
		case instructions
		case blobs
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let hexBlobs = blobs.map { $0.hex() }

		try container.encode(instructions, forKey: .instructions)
		try container.encode(hexBlobs, forKey: .blobs)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let instructions: ManifestInstructions = try container.decode(ManifestInstructions.self, forKey: .instructions)
		let hexBlobs = (try? container.decode([String].self, forKey: .blobs)) ?? []
		let blobs = try hexBlobs.map { try [UInt8](hex: $0) }
		self.init(instructions: instructions, blobs: blobs)
	}
}
