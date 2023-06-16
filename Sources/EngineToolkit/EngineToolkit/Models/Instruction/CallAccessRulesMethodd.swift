import Foundation

// MARK: - CallAccessRulesMethod
public struct CallAccessRulesMethod: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callAccessRulesMethod
	public func embed() -> Instruction {
		.callAccessRulesMethod(self)
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
}

extension CallAccessRulesMethod {
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

		try container.encodeValue(receiver, forKey: .receiver)
		try container.encodeValue(methodName, forKey: .methodName)
		try container.encode(arguments, forKey: .arguments)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let componentAddress: ComponentAddress = try container.decodeValue(forKey: .receiver)
		try self.init(
			receiver: componentAddress,
			methodName: container.decodeValue(forKey: .methodName),
			arguments: container.decodeIfPresent([ManifestASTValue].self, forKey: .arguments) ?? []
		)
	}
}
