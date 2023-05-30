import CasePaths
import Cryptography
import Prelude

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol {
	var kind: FactorSourceKind { get }
	var common: FactorSource.Common { get }
}

extension BaseFactorSourceProtocol {
	public typealias ID = FactorSourceID
	public var id: FactorSourceID {
		common.id
	}

	public var cryptoParameters: FactorSource.CryptoParameters {
		common.cryptoParameters
	}

	public var addedOn: Date {
		common.addedOn
	}

	public var lastUsedOn: Date {
		common.lastUsedOn
	}
}

// MARK: - FactorSource
public enum FactorSource: BaseFactorSourceProtocol, Sendable, Hashable, Codable, Identifiable {
	case device(DeviceFactorSource)
	case ledger(LedgerHardwareWalletFactorSource)
	case offDeviceMnemonic(OffDeviceMnemonic)
}

extension FactorSource {
	public var common: FactorSource.Common {
		property(\.common)
	}

	public var kind: FactorSourceKind {
		property(\.kind)
	}

	private func property<Property>(_ keyPath: KeyPath<BaseFactorSourceProtocol, Property>) -> Property {
		switch self {
		case let .device(factorSource): return factorSource[keyPath: keyPath]
		case let .ledger(factorSource): return factorSource[keyPath: keyPath]
		case let .offDeviceMnemonic(factorSource): return factorSource[keyPath: keyPath]
		}
	}
}

extension FactorSource {
	private enum CodingKeys: String, CodingKey {
		case discriminator, device, ledgerHQHardwareWallet, offDeviceMnemonic
	}

	public func encode(to encoder: Encoder) throws {
		var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
		try keyedContainer.encode(kind, forKey: .discriminator)
		switch self {
		case let .device(device):
			try keyedContainer.encode(device, forKey: .device)
		case let .ledger(ledger):
			try keyedContainer.encode(ledger, forKey: .ledgerHQHardwareWallet)
		case let .offDeviceMnemonic(ledger):
			try keyedContainer.encode(ledger, forKey: .offDeviceMnemonic)
		}
	}

	public init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try keyedContainer.decode(FactorSourceKind.self, forKey: .discriminator)
		switch discriminator {
		case .device:
			self = try .device(
				keyedContainer.decode(DeviceFactorSource.self, forKey: .device)
			)
		case .ledgerHQHardwareWallet:
			self = try .ledger(
				keyedContainer.decode(LedgerHardwareWalletFactorSource.self, forKey: .ledgerHQHardwareWallet)
			)
		case .offDeviceMnemonic:
			self = try .offDeviceMnemonic(
				keyedContainer.decode(OffDeviceMnemonic.self, forKey: .offDeviceMnemonic)
			)
		}
	}
}

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol: BaseFactorSourceProtocol, Sendable, Hashable, Codable {
	static var kind: FactorSourceKind { get }
	static var casePath: CasePath<FactorSource, Self> { get }
}

extension FactorSourceProtocol {
	public var kind: FactorSourceKind { Self.kind }
	public static var casePath: CasePath<FactorSource, Self> { Self.casePath }
}

extension FactorSourceProtocol {
	public func embed() -> FactorSource {
		casePath.embed(self)
	}

	public static func extract(from factorSource: FactorSource) -> Self? {
		casePath.extract(from: factorSource)
	}
}

extension FactorSource {
	public func extract<F>(_ type: F.Type) -> F? where F: FactorSourceProtocol {
		F.extract(from: self)
	}

	public func extract<F>(as _: F.Type) throws -> F where F: FactorSourceProtocol {
		guard let extracted = extract(F.self) else {
			throw IncorrectFactorSourceType(expectedKind: F.kind, actualKind: kind)
		}
		return extracted
	}
}

// MARK: - IncorrectFactorSourceType
public struct IncorrectFactorSourceType: Swift.Error {
	public let expectedKind: FactorSourceKind
	public let actualKind: FactorSourceKind
}

// MARK: - DeviceFactorSource
public struct DeviceFactorSource: FactorSourceProtocol {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .device
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.device

	public struct Hint: Sendable, Hashable, Codable {
		/// "iPhone RED"
		// The reason why this is mutable (`var`) instead of immutable `let` is
		// an implementation detailed on iOS, where reading the device name
		// and model is `async` but we want to be able to `sync` create the
		// profile, thus this property at a later point in time where an async
		// context is available.
		//
		public var name: Name; public typealias Name = Tagged<(Self, name: ()), String>

		/// "iPhone SE 2nd gen"
		// The reason why this is mutable (`var`) instead of immutable `let` is
		// an implementation detailed on iOS, where reading the device name
		// and model is `async` but we want to be able to `sync` create the
		// profile, thus this property at a later point in time where an async
		// context is available.
		//
		public var model: Model; public typealias Model = Tagged<(Self, model: ()), String>
	}

	public let common: FactorSource.Common
	public var hint: Hint

	/// nil for olympia
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?
}

// MARK: - FactorSource.Common
extension FactorSource {
	public struct Common: Sendable, Hashable, Codable {
		/// Canonical identifier which uniquely identifies this factor source
		public let id: FactorSourceID

		/// When this factor source for originally added by the user.
		public let addedOn: Date

		/// Date of last usage of this factor source
		///
		/// This is the only mutable property, it is mutable
		/// since we will update it every time this FactorSource
		/// is used.
		public var lastUsedOn: Date

		/// Curve/Derivation scheme
		public let cryptoParameters: FactorSource.CryptoParameters
	}
}

// MARK: - OffDeviceMnemonic
public struct OffDeviceMnemonic: FactorSourceProtocol {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .offDeviceMnemonic
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.offDeviceMnemonic

	public struct Hint: Sendable, Hashable, Codable {
		/// "Horse battery"
		public var story: Story; public typealias Story = Tagged<(Self, story: ()), String>

		/// "In a book at my safe place"
		public var backupLocation: BackupLocation; public typealias BackupLocation = Tagged<(Self, backupLocation: ()), String>
	}

	public struct BIP39Parameters: Sendable, Hashable, Codable {
		public let wordCount: BIP39.WordCount
		public let language: BIP39.Language
		public let bip39PassphraseSpecified: Bool
	}

	public var common: FactorSource.Common
	public var hint: Hint
	public let bip39Parameters: BIP39Parameters
}

// MARK: - BIP39.WordCount + Codable
extension BIP39.WordCount: Codable {}

// MARK: - BIP39.Language + Codable
extension BIP39.Language: Codable {}
