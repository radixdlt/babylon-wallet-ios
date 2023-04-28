import ClientPrelude
import Profile

// MARK: - FactorSourcesClient
public struct FactorSourcesClient: Sendable {
	public var getFactorSources: GetFactorSources
	public var factorSourcesAsyncSequence: FactorSourcesAsyncSequence
	public var addPrivateHDFactorSource: AddPrivateHDFactorSource
	public var checkIfHasOlympiaFactorSourceForAccounts: CheckIfHasOlympiaFactorSourceForAccounts
	public var addOffDeviceFactorSource: AddOffDeviceFactorSource
	public var getSigningFactors: GetSigningFactors

	public init(
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource,
		checkIfHasOlympiaFactorSourceForAccounts: @escaping CheckIfHasOlympiaFactorSourceForAccounts,
		addOffDeviceFactorSource: @escaping AddOffDeviceFactorSource,
		getSigningFactors: @escaping GetSigningFactors
	) {
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
		self.checkIfHasOlympiaFactorSourceForAccounts = checkIfHasOlympiaFactorSourceForAccounts
		self.addOffDeviceFactorSource = addOffDeviceFactorSource
		self.getSigningFactors = getSigningFactors
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (PrivateHDFactorSource) async throws -> FactorSourceID
	public typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceID?
	public typealias AddOffDeviceFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias GetSigningFactors = @Sendable (NetworkID, NonEmpty<Set<Profile.Network.Account>>) async throws -> SigningFactors
}

public typealias SigningFactors = OrderedDictionary<FactorSourceKind, NonEmpty<OrderedSet<SigningFactor>>>

extension SigningFactors {
	public var signerCount: Int {
		var count = 0
		for signingFactors in values {
			for signingFactor in signingFactors {
				count += signingFactor.signers.count
			}
		}
		return count
	}
}

// MARK: - SigningFactor
public struct SigningFactor: Sendable, Hashable {
	public typealias SignersPerAccount = NonEmpty<[Profile.Network.Account.ID: Signer]>

	public let factorSource: FactorSource
	public let signers: SignersPerAccount
	public init(factorSource: FactorSource, signers: SignersPerAccount) {
		self.factorSource = factorSource
		self.signers = signers
	}

	public struct Signer: Sendable, Hashable {
		public let account: Profile.Network.Account
		public let factorInstancesRequiredToSign: Set<FactorInstance>
		public init(account: Profile.Network.Account, factorInstancesRequiredToSign: Set<FactorInstance>) {
			self.account = account
			self.factorInstancesRequiredToSign = factorInstancesRequiredToSign
		}

		public func addingFactorInstance(_ factorInstance: FactorInstance) -> Self {
			var factorInstances = factorInstancesRequiredToSign
			factorInstances.insert(factorInstance)
			return .init(account: account, factorInstancesRequiredToSign: factorInstances)
		}
	}

	public func addingFactorInstance(_ factorInstance: FactorInstance, for account: Profile.Network.Account) -> Self {
		var signers = signers
		let signer = signers[account.id] ?? .init(account: account, factorInstancesRequiredToSign: [])
		signers.updateValue(signer.addingFactorInstance(factorInstance), forKey: account.id)
		return .init(factorSource: factorSource, signers: signers)
	}
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
