@testable import Profile
import TestingPrelude

// MARK: - SnapshotTestVector
public struct SnapshotTestVector: Codable, Equatable {
	/// Prefix with "_" combined with JSONEncoder output format `.sortedKeys` to get it in top
	private let _snapshotVersion: ProfileSnapshot.Header.Version
	public var snapshotVersion: ProfileSnapshot.Header.Version { _snapshotVersion }
	public let mnemonics: [IdentifiableMnemonic]
	public let encryptedSnapshots: [EncryptedSnapshotWithPassword]
	public let plaintext: ProfileSnapshot

	public init(
		mnemonics: [IdentifiableMnemonic],
		encryptedSnapshots: [EncryptedSnapshotWithPassword],
		plaintext: ProfileSnapshot
	) throws {
		self._snapshotVersion = plaintext.header.snapshotVersion
		self.mnemonics = mnemonics
		self.encryptedSnapshots = encryptedSnapshots
		self.plaintext = plaintext
		try validate()
	}
}

// MARK: SnapshotTestVector.IdentifiableMnemonic
extension SnapshotTestVector {
	public struct IdentifiableMnemonic: Codable, Equatable {
		public let factorSourceID: FactorSourceID
		public let mnemonicWithPassphrase: MnemonicWithPassphrase

		public init(
			mnemonicWithPassphrase: MnemonicWithPassphrase
		) throws {
			self.factorSourceID = try mnemonicWithPassphrase.deviceFactorSourceID().embed()
			self.mnemonicWithPassphrase = mnemonicWithPassphrase
		}
	}
}

// MARK: SnapshotTestVector.EncryptedSnapshotWithPassword
extension SnapshotTestVector {
	public struct EncryptedSnapshotWithPassword: Codable, Equatable {
		public let password: String
		public let snapshot: EncryptedProfileSnapshot
		func decrypted() throws -> ProfileSnapshot {
			try snapshot.decrypt(password: password)
		}
	}
}

// MARK: - FactorSourceNotFound
struct FactorSourceNotFound: Error {}

// MARK: - MnemonicNotFound
struct MnemonicNotFound: Error {}

// MARK: - PublicKeyDiscrepancy
struct PublicKeyDiscrepancy: Error {}

extension SnapshotTestVector {
	/// Returns the decrypted ProfileSnapshots which are all proven to be equal to `self.plaintext`
	@discardableResult
	public func validate() throws -> [ProfileSnapshot] {
		let decryptions = try encryptedSnapshots.map { try $0.decrypted() }
		guard decryptions.allSatisfy({ $0 == plaintext }) else {
			struct EncryptedSnapshotDoesNotEqualPlaintext: Error {}
			throw EncryptedSnapshotDoesNotEqualPlaintext()
		}
		guard
			Set(plaintext.factorSources.filter { $0.kind == .device }.map(\.id)) == Set(mnemonics.map(\.factorSourceID))
		else {
			struct MissingMnemonic: Error {}
			throw MissingMnemonic()
		}

		try validateAllEntitiesWithMnemonics()

		return decryptions
	}

	public func validateAllEntitiesWithMnemonics() throws {
		for network in plaintext.networks.values {
			func validate<Entity: EntityProtocol>(_ entity: Entity) throws {
				switch entity.securityState {
				case let .unsecured(entityControl):
					let txSignFactorInstance = entityControl.transactionSigning
					let factorSourceID = txSignFactorInstance.factorSourceID.embed()
					guard factorSourceID.kind == .device else { return }
					guard
						let factorSource = plaintext.factorSources.first(where: { $0.id == factorSourceID })
					else {
						throw FactorSourceNotFound()
					}
					guard
						let mnemonic = mnemonics.first(where: { $0.factorSourceID == factorSourceID })
					else {
						print(mnemonics.map(\.factorSourceID))

						throw MnemonicNotFound()
					}

					let publicKey = try mnemonic.mnemonicWithPassphrase.hdRoot().derivePublicKey(
						path: txSignFactorInstance.derivationPath,
						curve: txSignFactorInstance.derivationPath.curveForScheme
					)

					guard publicKey == txSignFactorInstance.publicKey else {
						throw PublicKeyDiscrepancy()
					}
					// all good
				}
			}
			try network.accounts.forEach(validate(_:))
			try network.personas.forEach(validate(_:))
		}
	}

	public static func encrypting(
		plaintext: ProfileSnapshot,
		mnemonics: [IdentifiableMnemonic],
		passwords: [String]
	) throws -> Self {
		let kdfScheme = PasswordBasedKeyDerivationScheme.default
		let encryptionScheme = EncryptionScheme.default
		let encryptions = try passwords.map { password in
			let encryption = try plaintext.encrypt(
				password: password,
				kdfScheme: kdfScheme,
				encryptionScheme: encryptionScheme
			)
			return EncryptedSnapshotWithPassword(
				password: password,
				snapshot: encryption
			)
		}
		return try .init(
			mnemonics: mnemonics,
			encryptedSnapshots: encryptions,
			plaintext: plaintext
		)
	}
}
