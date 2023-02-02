import Foundation

// MARK: - PublishPackageWithOwner
public struct PublishPackageWithOwner: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .publishPackageWithOwner
	public func embed() -> Instruction {
		.publishPackageWithOwner(self)
	}

	// MARK: Stored properties

	public let code: Blob
	public let abi: Blob
	public let ownerBadge: NonFungibleGlobalId

	// MARK: Init

	public init(code: Blob, abi: Blob, ownerBadge: NonFungibleGlobalId) {
		self.code = code
		self.abi = abi
		self.ownerBadge = ownerBadge
	}
}

public extension PublishPackageWithOwner {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case ownerBadge = "owner_badge"
		case code
		case abi
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(code, forKey: .code)
		try container.encode(abi, forKey: .abi)
		try container.encode(ownerBadge, forKey: .ownerBadge)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			code: container.decode(Blob.self, forKey: .code),
			abi: container.decode(Blob.self, forKey: .abi),
			ownerBadge: container.decode(NonFungibleGlobalId.self, forKey: .ownerBadge)
		)
	}
}
