import Foundation

// MARK: - CallNativeMethod
public struct CallNativeMethod: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callNativeMethod
	public func embed() -> Instruction {
		.callNativeMethod(self)
	}

	// MARK: Stored properties
	public let receiver: RENode
	public let methodName: String
	public let arguments: [Value_]

	// MARK: Init

	public init(receiver: RENode, methodName: String, arguments: [Value_] = []) {
		self.receiver = receiver
		self.methodName = methodName
		self.arguments = arguments
	}

	public init(
		receiver: RENode,
		methodName: String,
		@ValuesBuilder buildValues: () throws -> [any ValueProtocol]
	) rethrows {
		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: try buildValues().map { $0.embedValue() }
		)
	}

	public init(
		receiver: RENode,
		methodName: String,
		@SpecificValuesBuilder buildValues: () throws -> [Value_]
	) rethrows {
		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: try buildValues()
		)
	}

	public init(
		receiver: RENode,
		methodName: String,
		@SpecificValuesBuilder buildValue: () throws -> Value_
	) rethrows {
		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: [try buildValue()]
		)
	}
}

public extension CallNativeMethod {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case receiver
		case methodName = "method_name"
		case arguments
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(receiver, forKey: .receiver)
		try container.encode(methodName.proxyEncodable, forKey: .methodName)
		try container.encode(arguments, forKey: .arguments)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let receiver = try container.decode(RENode.self, forKey: .receiver)
		let methodName = try container.decode(String.ProxyDecodable.self, forKey: .methodName).decoded
		let arguments = try container.decodeIfPresent([Value_].self, forKey: .arguments) ?? []

		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: arguments
		)
	}
}
