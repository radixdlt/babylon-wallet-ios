import Foundation

// MARK: - ClaimPackageRoyalty
public struct ClaimPackageRoyalty: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .claimPackageRoyalty
	public func embed() -> Instruction {
		.claimPackageRoyalty(self)
	}

	// MARK: Stored properties

	public let packageAddress: PackageAddress

	// MARK: Init

	public init(packageAddress: PackageAddress) {
		self.packageAddress = packageAddress
	}
}

extension ClaimPackageRoyalty {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case packageAddress = "package_address"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(packageAddress, forKey: .packageAddress)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let packageAddress = try container.decode(PackageAddress.self, forKey: .packageAddress)

		self.init(packageAddress: packageAddress)
	}
}
