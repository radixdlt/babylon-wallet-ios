// MARK: - RENode
public enum RENode: Codable, Equatable, Hashable, Sendable {
	case bucket(TransientIdentifier)
	case proof(TransientIdentifier)

	case authZoneStack(UInt32)
	case worktop

	case global(String)
	case keyValueStore(RENodeIdentifier)
	case nonFungibleStore(RENodeIdentifier)
	case component(RENodeIdentifier)
	case epochManager(RENodeIdentifier)
	case vault(RENodeIdentifier)
	case resourceManager(RENodeIdentifier)
	case package(RENodeIdentifier)
	case clock(RENodeIdentifier)
}

// MARK: RENode.Kind
public extension RENode {
	enum Kind: String, Codable, Sendable, Hashable {
		case bucket = "Bucket"
		case proof = "Proof"

		case authZoneStack = "AuthZoneStack"
		case worktop = "Worktop"

		case global = "Global"
		case keyValueStore = "KeyValueStore"
		case nonFungibleStore = "NonFungibleStore"
		case component = "Component"
		case epochManager = "EpochManager"
		case vault = "Vault"
		case resourceManager = "ResourceManager"
		case package = "Package"
		case clock = "Clock"
	}
}

public extension RENode {
	var kind: Kind {
		switch self {
		case .bucket:
			return .bucket
		case .proof:
			return .proof

		case .authZoneStack:
			return .authZoneStack
		case .worktop:
			return .worktop

		case .global:
			return .global
		case .keyValueStore:
			return .keyValueStore
		case .nonFungibleStore:
			return .nonFungibleStore
		case .component:
			return .component
		case .epochManager:
			return .epochManager
		case .vault:
			return .vault
		case .resourceManager:
			return .resourceManager
		case .package:
			return .package
		case .clock:
			return .clock
		}
	}
}

public extension RENode {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type, identifier
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.kind, forKey: .type)

		switch self {
		case let .bucket(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .proof(identifier):
			try container.encode(identifier, forKey: .identifier)

		case let .authZoneStack(identifier):
			try container.encode(String(identifier), forKey: .identifier)
		case .worktop:
			break

		case let .global(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .keyValueStore(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .nonFungibleStore(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .component(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .epochManager(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .vault(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .resourceManager(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .package(identifier):
			try container.encode(identifier, forKey: .identifier)
		case let .clock(identifier):
			try container.encode(identifier, forKey: .identifier)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(RENode.Kind.self, forKey: .type)

		switch type {
		case .bucket:
			self = try .bucket(container.decode(TransientIdentifier.self, forKey: .identifier))
		case .proof:
			self = try .proof(container.decode(TransientIdentifier.self, forKey: .identifier))

		case .authZoneStack:
			let identifierString = try container.decode(String.self, forKey: .identifier)
			guard let identifierValue = UInt32(identifierString) else {
				throw SborDecodeError(value: "Auth zone stack must be a valid 32-bit unsigned integer")
			}
			self = .authZoneStack(identifierValue)
		case .worktop:
			self = .worktop

		case .global:
			self = try .global(container.decode(String.self, forKey: .identifier))
		case .keyValueStore:
			self = try .keyValueStore(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .nonFungibleStore:
			self = try .nonFungibleStore(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .component:
			self = try .component(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .epochManager:
			self = try .epochManager(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .vault:
			self = try .vault(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .resourceManager:
			self = try .resourceManager(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .package:
			self = try .package(container.decode(RENodeIdentifier.self, forKey: .identifier))
		case .clock:
			self = try .clock(container.decode(RENodeIdentifier.self, forKey: .identifier))
		}
	}
}

// MARK: - RENodeIdentifier
public struct RENodeIdentifier: Codable, Equatable, Hashable, Sendable {
	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		// TODO: Validation of length of Hash
		try self.init(bytes: [UInt8](hex: hex))
	}
}

public extension RENodeIdentifier {
	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.bytes.hex)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(hex: container.decode(String.self))
	}
}
