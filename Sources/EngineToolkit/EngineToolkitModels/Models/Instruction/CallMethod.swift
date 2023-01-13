import Foundation

// MARK: - CallMethod
public struct CallMethod: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .callMethod
	public func embed() -> Instruction {
		.callMethod(self)
	}

	// MARK: Stored properties
	public let receiver: CallMethodReceiver
	public let methodName: String
	public let arguments: [Value_]

	// MARK: Init

	public init<Receiver: CallMethodReceiverCompatible>(receiver: Receiver, methodName: String, arguments: [Value_] = []) {
		self.receiver = receiver.toCallMethodReceiver()
		self.methodName = methodName
		self.arguments = arguments
	}

	public init<Receiver: CallMethodReceiverCompatible>(
		receiver: Receiver,
		methodName: String,
		@ValuesBuilder buildValues: () throws -> [any ValueProtocol]
	) rethrows {
		self.init(
			receiver: receiver.toCallMethodReceiver(),
			methodName: methodName,
			arguments: try buildValues().map { $0.embedValue() }
		)
	}

	public init<Receiver: CallMethodReceiverCompatible>(
		receiver: Receiver,
		methodName: String,
		@SpecificValuesBuilder buildValues: () throws -> [Value_]
	) rethrows {
		self.init(
			receiver: receiver.toCallMethodReceiver(),
			methodName: methodName,
			arguments: try buildValues()
		)
	}

	public init<Receiver: CallMethodReceiverCompatible>(
		receiver: Receiver,
		methodName: String,
		@SpecificValuesBuilder buildValue: () throws -> Value_
	) rethrows {
		self.init(
			receiver: receiver.toCallMethodReceiver(),
			methodName: methodName,
			arguments: [try buildValue()]
		)
	}
}

public extension CallMethod {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case receiver = "component_address"
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

		let receiver = try container.decode(CallMethodReceiver.self, forKey: .receiver)
		let methodName = try container.decode(String.ProxyDecodable.self, forKey: .methodName).decoded
		let arguments = try container.decodeIfPresent([Value_].self, forKey: .arguments) ?? []

		self.init(
			receiver: receiver,
			methodName: methodName,
			arguments: arguments
		)
	}
}

// MARK: - CallMethodReceiverCompatible
public protocol CallMethodReceiverCompatible {
	func toCallMethodReceiver() -> CallMethodReceiver
}

// MARK: - CallMethodReceiver
public enum CallMethodReceiver: Sendable, Codable, Hashable, Equatable, CallMethodReceiverCompatible {
	case component(Component)
	case componentAddress(ComponentAddress)
}

public extension CallMethodReceiver {
	init(component: Component) {
		self = .component(component)
	}

	init(componentAddress: ComponentAddress) {
		self = .componentAddress(componentAddress)
	}
}

public extension CallMethodReceiver {
	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .component(receiver):
			try receiver.encode(to: encoder)
		case let .componentAddress(receiver):
			try receiver.encode(to: encoder)
		}
	}

	init(from decoder: Decoder) throws {
		do {
			self = try .componentAddress(.init(from: decoder))
		} catch {
			do {
				self = try .component(.init(from: decoder))
			} catch {
				throw SborDecodeError(value: "CallMethodReceiver must either be a `Component` or a `ComponentAddress`.")
			}
		}
	}
}

public extension CallMethodReceiver {
	func toCallMethodReceiver() -> CallMethodReceiver {
		self
	}

	func isAccountComponent() -> Bool {
		switch self {
		case .component:
			// TODO: We should not assume that any `Component` receiver is not an account.
			// We should instead call the Gateway API and try to get the account component address
			return false
		case let .componentAddress(componentAddress):
			if componentAddress.address.contains("account") {
				return true
			} else {
				return false
			}
		}
	}
}
