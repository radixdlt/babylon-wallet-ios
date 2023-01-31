import Foundation

// MARK: - SetPackageRoyaltyConfig
public struct SetPackageRoyaltyConfig: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setPackageRoyaltyConfig
	public func embed() -> Instruction {
		.setPackageRoyaltyConfig(self)
	}

	// MARK: Stored properties

	public let packageAddress: PackageAddress
	public let royaltyConfig: Map_

	// MARK: Init

	public init(packageAddress: PackageAddress, royaltyConfig: Map_) {
		self.packageAddress = packageAddress
		self.royaltyConfig = royaltyConfig
	}
}

public extension SetPackageRoyaltyConfig {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case packageAddress = "package_address"
		case royaltyConfig = "royalty_config"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(packageAddress, forKey: .packageAddress)
		try container.encode(royaltyConfig, forKey: .royaltyConfig)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let packageAddress = try container.decode(PackageAddress.self, forKey: .packageAddress)
		let royaltyConfig = try container.decode(Map_.self, forKey: .royaltyConfig)

		self.init(packageAddress: packageAddress, royaltyConfig: royaltyConfig)
	}
}
