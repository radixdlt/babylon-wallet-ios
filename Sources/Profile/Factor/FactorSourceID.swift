import Foundation
import Prelude

// MARK: - BaseFactorSourceIDProtocol
public protocol BaseFactorSourceIDProtocol {
	var kind: FactorSourceKind { get }
}

// MARK: - FactorSourceIDProtocol
public protocol FactorSourceIDProtocol: BaseFactorSourceIDProtocol, Sendable, Hashable, CustomStringConvertible, Codable {
	associatedtype Body: Sendable & Hashable & CustomStringConvertible
	var body: Body { get }
}

extension FactorSourceIDProtocol {
	public var description: String {
		"\(kind):\(String(describing: body))"
	}
}

// MARK: - FactorSourceID
public enum FactorSourceID: BaseFactorSourceIDProtocol, Sendable, Hashable, CustomStringConvertible, Codable {
	case hash(FromHash)
	case address(FromAddress)
}

extension FactorSourceID {
	public struct FromHash: FactorSourceIDProtocol {
		public let kind: FactorSourceKind
		public let body: HexCodable32Bytes

		public init(
			kind: FactorSourceKind,
			body: HexCodable32Bytes
		) {
			self.kind = kind
			self.body = body
		}
	}

	public struct FromAddress: FactorSourceIDProtocol {
		public let kind: FactorSourceKind
		public let body: AccountAddress
	}
}

extension FactorSourceID.FromHash {
	public init(kind: FactorSourceKind, hash: some DataProtocol) throws {
		try self.init(kind: kind, body: .init(data: Data(hash)))
	}

	public static func device(hash: some DataProtocol) throws -> Self {
		try self.init(kind: .device, hash: hash)
	}
}

extension FactorSourceID {
	public init(kind: FactorSourceKind, hash: some DataProtocol) throws {
		self = try .hash(.init(kind: kind, hash: hash))
	}

	public static func device(hash: some DataProtocol) throws -> Self {
		try .hash(.device(hash: hash))
	}
}

#if DEBUG
extension FactorSourceID {
	public static func device(hash: String) throws -> Self {
		try .hash(.device(hash: Data(hex: hash)))
	}
}
#endif

extension FactorSourceID {
	private func property<Property>(
		_ keyPath: KeyPath<any FactorSourceIDProtocol, Property>
	) -> Property {
		switch self {
		case let .address(factorSourceID):
			return factorSourceID[keyPath: keyPath]
		case let .hash(factorSourceID):
			return factorSourceID[keyPath: keyPath]
		}
	}

	public var description: String {
		property(\.description)
	}

	public var kind: FactorSourceKind {
		property(\.kind)
	}
}

extension FactorSourceID {
	public enum Discriminator: String, Codable {
		case fromHash
		case fromAddress
	}

	private var discriminator: Discriminator {
		switch self {
		case .hash: return .fromHash
		case .address: return .fromAddress
		}
	}

	private enum CodingKeys: String, CodingKey {
		case discriminator, fromHash, fromAddress
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(discriminator, forKey: .discriminator)
		switch self {
		case let .hash(id):
			try keyedContainer.encode(id, forKey: .fromHash)
		case let .address(id):
			try keyedContainer.encode(id, forKey: .fromAddress)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(Discriminator.self, forKey: .discriminator)

		switch discriminator {
		case .fromHash:
			self = try .hash(
				keyedContainer.decode(FromHash.self, forKey: .fromHash)
			)
		case .fromAddress:
			self = try .address(
				keyedContainer.decode(FromAddress.self, forKey: .fromAddress)
			)
		}
	}
}

#if DEBUG
extension FactorSourceID {
	public static let previewValue = Self.preview(.device)
	public static func preview(_ factorSourceKind: FactorSourceKind) -> Self {
		.hash(.init(kind: factorSourceKind, body: .deadbeef))
	}
}
#endif // DEBUG
