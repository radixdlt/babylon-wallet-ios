import Foundation

// MARK: - MintUuidNonFungible
public struct MintUuidNonFungible: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .mintUuidNonFungible
	public func embed() -> Instruction {
		.mintUuidNonFungible(self)
	}

	// MARK: Stored properties

	public let resourceAddress: ResourceAddress
	public let entries: Value_

	// MARK: Init

	public init(
		resourceAddress: ResourceAddress,
		entries: Value_
	) {
		self.resourceAddress = resourceAddress
		self.entries = entries
	}
}

public extension MintUuidNonFungible {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entries
		case resourceAddress = "resource_address"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(entries, forKey: .entries)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			entries: container.decode(Value_.self, forKey: .entries)
		)
	}
}
