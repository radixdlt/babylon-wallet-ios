import CasePaths
import Cryptography
import Prelude

// MARK: - BaseFactorSourceProtocol
public protocol BaseFactorSourceProtocol {
	var kind: FactorSourceKind { get }
	var common: FactorSource.Common { get set }
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

	public var supportsOlympia: Bool {
		cryptoParameters.supportsOlympia
	}
}

// MARK: - FactorSource
public enum FactorSource: BaseFactorSourceProtocol, Sendable, Hashable, Codable, Identifiable {
	case device(DeviceFactorSource)
	case ledger(LedgerHardwareWalletFactorSource)
	case offDeviceMnemonic(OffDeviceMnemonicFactorSource)
}

extension FactorSource {
	public var common: FactorSource.Common {
		get { property(\.common) }
		set {
			update(\.common, to: newValue)
		}
	}

	public var kind: FactorSourceKind {
		property(\.kind)
	}

	public mutating func update<Property>(
		_ writableKeyPath: WritableKeyPath<any FactorSourceProtocol, Property>,
		to newValue: Property
	) {
		switch self {
		case var .device(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .ledger(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()

		case var .offDeviceMnemonic(factorSource as (any FactorSourceProtocol)):
			factorSource[keyPath: writableKeyPath] = newValue
			self = factorSource.embed()
		}
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
		try keyedContainer.encode(kind.discriminator, forKey: .discriminator)
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
		let discriminator = try keyedContainer.decode(FactorSourceKind.Discriminator.self, forKey: .discriminator)
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
				keyedContainer.decode(OffDeviceMnemonicFactorSource.self, forKey: .offDeviceMnemonic)
			)
		}
	}
}

// MARK: - FactorSourceProtocol
public protocol FactorSourceProtocol: BaseFactorSourceProtocol, Sendable, Hashable, Codable, Identifiable {
	static var kind: FactorSourceKind { get }
	static var casePath: CasePath<FactorSource, Self> { get }
}

extension FactorSourceProtocol {
	public typealias ID = FactorSourceID
	public var id: ID { common.id }
	public var kind: FactorSourceKind { Self.kind }
	public var casePath: CasePath<FactorSource, Self> { Self.casePath }
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

extension FactorSource.Common {
	public static func from(
		factorSourceKind: FactorSourceKind,
		hdRoot: HD.Root,
		cryptoParameters: FactorSource.CryptoParameters = .babylon,
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try .init(
			id: FactorSource.id(
				fromRoot: hdRoot,
				factorSourceKind: factorSourceKind
			),
			cryptoParameters: cryptoParameters,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public static func from(
		factorSourceKind: FactorSourceKind,
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		cryptoParameters: FactorSource.CryptoParameters = .babylon,
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try Self.from(
			factorSourceKind: factorSourceKind,
			hdRoot: mnemonicWithPassphrase.hdRoot(),
			cryptoParameters: cryptoParameters,
			addedOn: addedOn, lastUsedOn: lastUsedOn
		)
	}
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

	// Mutable so we can update "lastUsedOn"
	public var common: FactorSource.Common

	// Mutable so we can update "name"
	public var hint: Hint

	/// nil for olympia
	public var nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork?

	public init(
		common: FactorSource.Common,
		hint: Hint,
		nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork? = nil
	) {
		self.common = common
		self.hint = hint
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
	}
}

extension DeviceFactorSource {
	public static func from(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: Hint.Name = "",
		isOlympiaCompatible: Bool,
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try Self(
			common: .from(
				factorSourceKind: .device,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				cryptoParameters: isOlympiaCompatible ? .olympiaBackwardsCompatible : .babylon,
				addedOn: addedOn,
				lastUsedOn: lastUsedOn
			),
			hint: .init(name: name, model: model),
			nextDerivationIndicesPerNetwork: isOlympiaCompatible ? nil : .init()
		)
	}

	public static func babylon(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model,
		name: Hint.Name,
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try Self.from(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			model: model,
			name: name,
			isOlympiaCompatible: false,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}

	public static func olympia(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		model: Hint.Model = "",
		name: Hint.Name = "",
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try Self.from(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			model: model,
			name: name,
			isOlympiaCompatible: true,
			addedOn: addedOn,
			lastUsedOn: lastUsedOn
		)
	}
}

import EngineToolkitModels
extension DeviceFactorSource {
	public func nextDerivationIndex(for entityKind: EntityKind, networkID: NetworkID) throws -> Profile.Network.NextDerivationIndices.Index {
		guard let nextDerivationIndicesPerNetwork else {
			throw CalledPerivationPathOnOlympiaDeviceFactorNotSupported()
		}
		return nextDerivationIndicesPerNetwork.nextForEntity(kind: entityKind, networkID: networkID)
	}

	public func derivationPath(forNext entityKind: EntityKind, networkID: NetworkID) throws -> DerivationPath {
		guard let nextDerivationIndicesPerNetwork else {
			throw CalledPerivationPathOnOlympiaDeviceFactorNotSupported()
		}
		return try nextDerivationIndicesPerNetwork.derivationPathForNextEntity(
			kind: entityKind,
			networkID: networkID
		)
	}
}

// MARK: - CalledPerivationPathOnOlympiaDeviceFactorNotSupported
struct CalledPerivationPathOnOlympiaDeviceFactorNotSupported: Swift.Error {}

// MARK: - FactorSource.Common
extension FactorSource {
	public struct Common: Sendable, Hashable, Codable {
		/// Canonical identifier which uniquely identifies this factor source
		public let id: FactorSourceID

		/// Curve/Derivation scheme
		public let cryptoParameters: FactorSource.CryptoParameters

		/// When this factor source for originally added by the user.
		public let addedOn: Date

		/// Date of last usage of this factor source
		///
		/// This is the only mutable property, it is mutable
		/// since we will update it every time this FactorSource
		/// is used.
		public var lastUsedOn: Date

		public init(
			id: FactorSourceID,
			cryptoParameters: FactorSource.CryptoParameters = .babylon,
			addedOn: Date = .now,
			lastUsedOn: Date = .now
		) {
			self.id = id
			self.cryptoParameters = cryptoParameters
			self.addedOn = addedOn
			self.lastUsedOn = lastUsedOn
		}
	}
}

// MARK: - OffDeviceMnemonicFactorSource
public struct OffDeviceMnemonicFactorSource: FactorSourceProtocol {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .offDeviceMnemonic
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.offDeviceMnemonic

	public struct Hint: Sendable, Hashable, Codable {
		/// "Horse battery"
		public var story: Story; public typealias Story = Tagged<(Self, story: ()), String>

		/// "In a book at my safe place"
		public var backupLocation: BackupLocation; public typealias BackupLocation = Tagged<(Self, backupLocation: ()), String>

		public init(
			story: Story,
			backupLocation: BackupLocation
		) {
			self.story = story
			self.backupLocation = backupLocation
		}
	}

	public struct BIP39Parameters: Sendable, Hashable, Codable {
		public let wordCount: BIP39.WordCount
		public let language: BIP39.Language
		public let bip39PassphraseSpecified: Bool

		public init(
			wordCount: BIP39.WordCount,
			language: BIP39.Language,
			bip39PassphraseSpecified: Bool
		) {
			self.wordCount = wordCount
			self.language = language
			self.bip39PassphraseSpecified = bip39PassphraseSpecified
		}

		public init(mnemonicWithPassphrase: MnemonicWithPassphrase) {
			let mnemonic = mnemonicWithPassphrase.mnemonic
			self.init(wordCount: mnemonic.wordCount, language: mnemonic.language, bip39PassphraseSpecified: !mnemonicWithPassphrase.passphrase.isEmpty)
		}
	}

	public var common: FactorSource.Common
	public var hint: Hint
	public let bip39Parameters: BIP39Parameters

	public init(
		common: FactorSource.Common,
		hint: Hint,
		bip39Parameters: BIP39Parameters
	) {
		self.common = common
		self.hint = hint
		self.bip39Parameters = bip39Parameters
	}

	public static func from(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		story: Hint.Story,
		backupLocation: Hint.BackupLocation,
		addedOn: Date = .now,
		lastUsedOn: Date = .now
	) throws -> Self {
		try Self(
			common: .from(
				factorSourceKind: .device,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				cryptoParameters: .babylon,
				addedOn: addedOn,
				lastUsedOn: lastUsedOn
			),
			hint: .init(story: story, backupLocation: backupLocation),
			bip39Parameters: .init(mnemonicWithPassphrase: mnemonicWithPassphrase)
		)
	}
}

// MARK: - BIP39.WordCount + Codable
extension BIP39.WordCount: Codable {}

// MARK: - BIP39.Language + Codable
extension BIP39.Language: Codable {}
