import Foundation

// MARK: - CallMethod
public struct CallMethod: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callMethod
	public func embed() -> Instruction {
		.callMethod(self)
	}

	// MARK: Stored properties
	/// Temporary, will change to `Address`. This can actually only be either `ComponentAddress` or `Address_`.
	public let receiver: ManifestASTValue
	public let methodName: String
	public let arguments: [ManifestASTValue]

	// MARK: Computed properties

	/// Temporary. This can actually only be either `ComponentAddress` or `Address_`.
	public var receiverAsAccountComponentAddress: ComponentAddress? {
		switch receiver {
		case let .address(address) where address.address.starts(with: "account"):
			return ComponentAddress(address: address.address)
		case let .componentAddress(componentAddress):
			return componentAddress
		default:
			return nil
		}
	}

	// MARK: Init

	public init(receiver: ComponentAddress, methodName: String, arguments: [ManifestASTValue] = []) {
		self.receiver = .componentAddress(receiver)
		self.methodName = methodName
		self.arguments = arguments
	}

	public init(receiver: Address_, methodName: String, arguments: [ManifestASTValue] = []) {
		self.receiver = .address(receiver)
		self.methodName = methodName
		self.arguments = arguments
	}

	public init(
		receiver: ComponentAddress,
		methodName: String,
		@ValuesBuilder buildValues: () throws -> [any ValueProtocol]
	) rethrows {
		try self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: buildValues().map { $0.embedValue() }
		)
	}

	public init(
		receiver: ComponentAddress,
		methodName: String,
		@SpecificValuesBuilder buildValues: () throws -> [ManifestASTValue]
	) rethrows {
		try self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: buildValues()
		)
	}

	public init(
		receiver: ComponentAddress,
		methodName: String,
		@SpecificValuesBuilder buildValue: () throws -> ManifestASTValue
	) rethrows {
		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: [try buildValue()]
		)
	}
}

extension CallMethod {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case receiver = "component_address"
		case methodName = "method_name"
		case arguments
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(receiver, forKey: .receiver)
		try container.encode(methodName.proxyEncodable, forKey: .methodName)
		try container.encode(arguments, forKey: .arguments)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.receiver = try container.decode(ManifestASTValue.self, forKey: .receiver)
		self.methodName = try container.decode(String.ProxyDecodable.self, forKey: .methodName).decoded
		self.arguments = try container.decodeIfPresent([ManifestASTValue].self, forKey: .arguments) ?? []
	}
}
