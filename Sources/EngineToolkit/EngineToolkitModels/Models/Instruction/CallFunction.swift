import Foundation

// MARK: - CallFunction
public struct CallFunction: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callFunction
	public func embed() -> Instruction {
		.callFunction(self)
	}

	// MARK: Stored properties
	public let packageAddress: PackageAddress
	public let blueprintName: String
	public let functionName: String
	public let arguments: [Value_]

	// MARK: Init

	public init(
		packageAddress: PackageAddress,
		blueprintName: String,
		functionName: String,
		arguments: [Value_] = []
	) {
		self.packageAddress = packageAddress
		self.blueprintName = blueprintName
		self.functionName = functionName
		self.arguments = arguments
	}

	public init(
		packageAddress: PackageAddress,
		blueprintName: String,
		functionName: String,
		@ValuesBuilder buildValues: () throws -> [any ValueProtocol]
	) rethrows {
		try self.init(
			packageAddress: packageAddress,
			blueprintName: blueprintName,
			functionName: functionName,
			arguments: buildValues().map { $0.embedValue() }
		)
	}

	public init(
		packageAddress: PackageAddress,
		blueprintName: String,
		functionName: String,
		@SpecificValuesBuilder buildValues: () throws -> [Value_]
	) rethrows {
		try self.init(
			packageAddress: packageAddress,
			blueprintName: blueprintName,
			functionName: functionName,
			arguments: buildValues()
		)
	}

	public init(
		packageAddress: PackageAddress,
		blueprintName: String,
		functionName: String,
		@SpecificValuesBuilder buildValue: () throws -> Value_
	) rethrows {
		try self.init(
			packageAddress: packageAddress,
			blueprintName: blueprintName,
			functionName: functionName,
			arguments: [buildValue()]
		)
	}
}

extension CallFunction {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case packageAddress = "package_address"
		case blueprintName = "blueprint_name"
		case functionName = "function_name"
		case arguments
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(packageAddress, forKey: .packageAddress)
		try container.encode(blueprintName.proxyEncodable, forKey: .blueprintName)
		try container.encode(functionName.proxyEncodable, forKey: .functionName)
		try container.encode(arguments, forKey: .arguments)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let packageAddress = try container.decode(PackageAddress.self, forKey: .packageAddress)
		let blueprintName = try container.decode(String.ProxyDecodable.self, forKey: .blueprintName).decoded
		let functionName = try container.decode(String.ProxyDecodable.self, forKey: .functionName).decoded
		let arguments = try container.decodeIfPresent([Value_].self, forKey: .arguments) ?? []

		self.init(
			packageAddress: packageAddress,
			blueprintName: blueprintName,
			functionName: functionName,
			arguments: arguments
		)
	}
}
