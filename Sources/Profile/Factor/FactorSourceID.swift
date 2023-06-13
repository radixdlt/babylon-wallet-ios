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

// MARK: - FactorSourceID_
public enum FactorSourceID_: BaseFactorSourceIDProtocol, Sendable, Hashable, CustomStringConvertible {
	case hash(FromHash)
	case address(FromAddress)
}

extension FactorSourceID_ {
	public struct FromHash: FactorSourceIDProtocol {
		public let kind: FactorSourceKind
		public let body: HexCodable32Bytes
	}

	public struct FromAddress: FactorSourceIDProtocol {
		public let kind: FactorSourceKind
		public let body: AccountAddress
	}
}

extension FactorSourceID_ {
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

extension FactorSourceID_ {
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

// MARK: - FactorSourceID
/// FactorSourceKind concatenated with hash of publicKey, in case of HD it is the Hash of the public key derived
/// using CAP26 derivationPath: m/44'/1022'/365'
public struct FactorSourceID: Sendable, Hashable, CodableViaHexCodable, CustomStringConvertible {
	public enum Error: String, Swift.Error, Hashable {
		case invalidByteCount
	}

	public var factorSourceKind: FactorSourceKind {
		let factorSourceKindRawValue = hexCodable[0]
		guard let factorSourceKind = FactorSourceKind(rawValue: factorSourceKindRawValue) else {
			fatalError("Invalid state, unknown factor source kind, value: \(factorSourceKindRawValue)")
		}
		return factorSourceKind
	}

	/// 33 bytes, consisting of `FactorSourceKind(1) || Hash(32)`
	public let hexCodable: HexCodable

	public init(hexCodable: HexCodable) throws {
		guard hexCodable.data.count == 33 else {
			throw Error.invalidByteCount
		}
		let factorSourceKindRawValue = hexCodable[0]
		guard let _ = FactorSourceKind(rawValue: factorSourceKindRawValue) else {
			throw UnknownFactorSourceKind(unknownValue: factorSourceKindRawValue)
		}
		self.hexCodable = hexCodable
	}

	public init(factorSourceKind: FactorSourceKind, hash: Data) throws {
		guard hash.count == 32 else {
			throw Error.invalidByteCount
		}
		self.hexCodable = .init(data: Data([factorSourceKind.rawValue]) + hash)
	}
}

// MARK: - UnknownFactorSourceKind
struct UnknownFactorSourceKind: Swift.Error {
	public let unknownValue: FactorSourceKind.RawValue
}

extension FactorSourceID {
	public var description: String {
		hexCodable.hex()
	}
}

#if DEBUG
extension FactorSourceID {
	public static let previewValue = Self.preview(.device)
	public static func preview(_ factorSourceKind: FactorSourceKind) -> Self {
		try! Self(factorSourceKind: factorSourceKind, hash: .deadbeef32Bytes)
	}
}
#endif // DEBUG
