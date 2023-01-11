import Foundation

public extension ManifestInstructions {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type
		case value
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .string(value):
			try container.encode(ManifestInstructionsKind.string, forKey: .type)
			try container.encode(value, forKey: .value)
		case let .json(value):
			try container.encode(ManifestInstructionsKind.json, forKey: .type)
			try container.encode(value, forKey: .value)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let manifestInstructionsKind: ManifestInstructionsKind = try container.decode(ManifestInstructionsKind.self, forKey: .type)

		switch manifestInstructionsKind {
		case .string:
			let manifestInstructions = try container.decode(String.self, forKey: .value)
			self = .string(manifestInstructions)
		case .json:
			let manifestInstructions = try container.decode([Instruction].self, forKey: .value)
			self = .json(manifestInstructions)
		}
	}
}
