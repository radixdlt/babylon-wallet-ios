import CasePaths
import Cryptography
import Prelude

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
		addedOn: Date? = nil,
		lastUsedOn: Date? = nil
	) throws -> Self {
		@Dependency(\.date) var date
		return try Self(
			common: .from(
				factorSourceKind: .device,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				cryptoParameters: .babylon,
				addedOn: addedOn ?? date(),
				lastUsedOn: lastUsedOn ?? date()
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
