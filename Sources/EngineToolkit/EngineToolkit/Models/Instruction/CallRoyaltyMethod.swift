import Foundation

// MARK: - CallRoyaltyMethod
public struct CallRoyaltyMethod: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callRoyaltyMethod
	public func embed() -> Instruction {
		.callRoyaltyMethod(self)
	}

	// MARK: Stored properties
	public let receiver: ComponentAddress
	public let methodName: String
	public let arguments: [ManifestASTValue]

	// MARK: Init

	public init(
		receiver: ComponentAddress,
		methodName: String,
		arguments: [ManifestASTValue] = []
	) {
		self.receiver = receiver
		self.methodName = methodName
		self.arguments = arguments
	}

	public init(
		receiver: AccountAddress,
		methodName: String,
		arguments: [ManifestASTValue] = []
	) {
		self.receiver = receiver.asComponentAddress
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

	#if swift(<5.8)
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

	#endif
}

extension CallRoyaltyMethod {
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

		try self.init(
			receiver: container.decode(ComponentAddress.self, forKey: .receiver),
			methodName: container.decode(String.ProxyDecodable.self, forKey: .methodName).decoded,
			arguments: container.decodeIfPresent([ManifestASTValue].self, forKey: .arguments) ?? []
		)
	}
}
