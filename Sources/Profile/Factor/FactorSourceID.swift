import CasePaths
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
	static var casePath: CasePath<FactorSourceID, Self> { get }
	func embed() -> FactorSourceID
}

extension FactorSourceIDProtocol {
	public var casePath: CasePath<FactorSourceID, Self> { Self.casePath }
	public func embed() -> FactorSourceID {
		casePath.embed(self)
	}

	public static func extract(from factorSourceID: FactorSourceID) -> Self? {
		casePath.extract(from: factorSourceID)
	}
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
	public func extract<F>(_ type: F.Type = F.self) -> F? where F: FactorSourceIDProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type = F.self) throws -> F where F: FactorSourceIDProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectFactorSourceIDType(actual: self.discriminator)
		}
		return extracted
	}
}

// MARK: - IncorrectFactorSourceIDType
public struct IncorrectFactorSourceIDType: Swift.Error {
	public let actual: FactorSourceID.Discriminator
}

extension FactorSourceID {
	public struct FromHash: FactorSourceIDProtocol {
		public static let casePath: CasePath<FactorSourceID, Self> = /FactorSourceID.hash
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
		public static let casePath: CasePath<FactorSourceID, Self> = /FactorSourceID.address
		public let kind: FactorSourceKind
		public let body: AccountAddress
	}
}

extension FactorSourceID.FromHash {
	public init(kind: FactorSourceKind, hash: some DataProtocol) throws {
		try self.init(kind: kind, body: .init(data: Data(hash)))
	}

	public init(kind: FactorSourceKind, mnemonicWithPassphrase: MnemonicWithPassphrase) throws {
		self = try FactorSource.id(fromRoot: mnemonicWithPassphrase.hdRoot(), factorSourceKind: kind)
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
extension FactorSourceID.FromHash {
	public static func device(hash: String) throws -> Self {
		try .device(hash: Data(hex: hash))
	}
}

extension FactorSourceID {
	public static func device(hash: String) throws -> Self {
		try .hash(.device(hash: hash))
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
	public enum Discriminator: String, Sendable, Hashable, Codable {
		case fromHash
		case fromAddress
	}

	public var discriminator: Discriminator {
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
