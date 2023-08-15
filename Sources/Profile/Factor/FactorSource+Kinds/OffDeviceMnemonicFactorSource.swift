import CasePaths
import Cryptography
import Prelude

// MARK: - OffDeviceMnemonicFactorSource
public struct OffDeviceMnemonicFactorSource: FactorSourceProtocol {
	public typealias ID = FactorSourceID.FromHash
	public let id: ID
	public var common: FactorSource.Common // We update `lastUsed`
	public let hint: Hint
	public let bip39Parameters: BIP39Parameters

	init(
		id: ID,
		common: FactorSource.Common,
		hint: Hint,
		bip39Parameters: BIP39Parameters
	) {
		precondition(id.kind == Self.kind)
		self.id = id
		self.common = common
		self.hint = hint
		self.bip39Parameters = bip39Parameters
	}
}

extension OffDeviceMnemonicFactorSource {
	/// Kind of factor source
	public static let kind: FactorSourceKind = .offDeviceMnemonic
	public static let casePath: CasePath<FactorSource, Self> = /FactorSource.offDeviceMnemonic
}

// MARK: OffDeviceMnemonicFactorSource.Hint
extension OffDeviceMnemonicFactorSource {
	public struct Hint: Sendable, Hashable, Codable {
		public typealias Label = Tagged<(Self, label: ()), String>

		/// "Horse battery"
		public let label: Label

		public init(
			label: Label
		) {
			self.label = label
		}
	}
}

// MARK: OffDeviceMnemonicFactorSource.BIP39Parameters
extension OffDeviceMnemonicFactorSource {
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
			self.init(
				wordCount: mnemonic.wordCount,
				language: mnemonic.language,
				bip39PassphraseSpecified: !mnemonicWithPassphrase.passphrase.isEmpty
			)
		}
	}
}

extension OffDeviceMnemonicFactorSource {
	public static func from(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		label: Hint.Label,
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		return try Self(
			id: .init(kind: .offDeviceMnemonic, mnemonicWithPassphrase: mnemonicWithPassphrase),
			common: .from(
				cryptoParameters: .babylon,
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
			),
			hint: .init(label: label),
			bip39Parameters: .init(mnemonicWithPassphrase: mnemonicWithPassphrase)
		)
	}
}

// MARK: - BIP39.WordCount + Codable
extension BIP39.WordCount: Codable {}

// MARK: - BIP39.Language + Codable
extension BIP39.Language: Codable {}
