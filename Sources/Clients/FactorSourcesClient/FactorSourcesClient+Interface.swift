import ClientPrelude
import Profile

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	public var addPrivateHDFactorSource: AddPrivateHDFactorSource
	public var checkIfHasOlympiaFactorSourceForAccounts: CheckIfHasOlympiaFactorSourceForAccounts
	public var addOffDeviceFactorSource: AddOffDeviceFactorSource
	public var getFactorsOfSigners: GetFactorsOfSigners

	public init(
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource,
		checkIfHasOlympiaFactorSourceForAccounts: @escaping CheckIfHasOlympiaFactorSourceForAccounts,
		addOffDeviceFactorSource: @escaping AddOffDeviceFactorSource,
		getFactorsOfSigners: @escaping GetFactorsOfSigners
	) {
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
		self.checkIfHasOlympiaFactorSourceForAccounts = checkIfHasOlympiaFactorSourceForAccounts
		self.addOffDeviceFactorSource = addOffDeviceFactorSource
		self.getFactorsOfSigners = getFactorsOfSigners
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (PrivateHDFactorSource) async throws -> FactorSourceID
	public typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceID?
	public typealias AddOffDeviceFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias GetFactorsOfSigners = @Sendable (Set<AccountAddress>) async throws -> FactorsOfSigners
}

// MARK: - FactorsOfSigners
public struct FactorsOfSigners: Sendable, Hashable {
	public let factorsOfSigners: Set<FactorsOfSigner>

	/// All factor sources references by all `requiredFactorInstances` of all `factorsOfSigners`.
	public let factorSources: Set<FactorSource>

	public init(
		factorsOfSigners: Set<FactorsOfSigner>,
		factorSources: Set<FactorSource>
	) {
		self.factorsOfSigners = factorsOfSigners
		self.factorSources = factorSources
	}
}

// MARK: - FactorsOfSigner
public struct FactorsOfSigner: Sendable, Hashable {
	/// signer
	public let signer: Profile.Network.Account
	/// required signing factors of `signer`
	public let requiredFactorInstances: Set<FactorInstance>
}

extension FactorSourcesClient {
	public func importOlympiaFactorSource(
		mnemonicWithPassphrase: MnemonicWithPassphrase
	) async throws -> FactorSourceID {
		let factorSource = try FactorSource.olympia(
			mnemonicWithPassphrase: mnemonicWithPassphrase
		)
		let privateFactorSource = try PrivateHDFactorSource(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			hdOnDeviceFactorSource: factorSource
		)
		return try await self.addPrivateHDFactorSource(privateFactorSource)
	}
}

// Move elsewhere?
import Cryptography
extension MnemonicWithPassphrase {
	@discardableResult
	public func validatePublicKeysOf(
		softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws -> Bool {
		let hdRoot = try self.hdRoot()

		for olympiaAccount in softwareAccounts {
			let path = olympiaAccount.path.fullPath

			let derivedPublicKey = try hdRoot.derivePrivateKey(
				path: path,
				curve: SECP256K1.self
			).publicKey

			guard derivedPublicKey == olympiaAccount.publicKey else {
				throw ValidateOlympiaAccountsFailure.publicKeyMismatch
			}
		}
		// PublicKeys matches
		return true
	}
}

// MARK: - ValidateOlympiaAccountsFailure
enum ValidateOlympiaAccountsFailure: LocalizedError {
	case publicKeyMismatch
}
