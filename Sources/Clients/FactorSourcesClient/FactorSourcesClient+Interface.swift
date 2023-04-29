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

public typealias SigningFactors = OrderedDictionary<FactorSourceKind, NonEmpty<Set<SigningFactor>>>

extension SigningFactors {
	public var signerCount: Int {
		values.flatMap { $0.map(\.signers.count) }.reduce(0, +)
	}
}

// MARK: - SigningFactor
public struct SigningFactor: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSource.ID
	public var id: ID { factorSource.id }
	public let factorSource: FactorSource
	public var signers: NonEmpty<IdentifiedArrayOf<Signer>>

	public init(
		factorSource: FactorSource,
		signers: NonEmpty<IdentifiedArrayOf<Signer>>
	) {
		self.factorSource = factorSource
		self.signers = signers
	}

	public init(
		factorSource: FactorSource,
		signer: Signer
	) {
		self.init(
			factorSource: factorSource,
			signers: .init(rawValue: .init(uniqueElements: [signer]))! // ok to force unwrap since we know we have one element.
		)
	}

	public struct Signer: Sendable, Hashable, Identifiable {
		public typealias ID = Profile.Network.Account.ID
		public var id: ID { account.id }
		public let account: Profile.Network.Account

		public let factorInstancesRequiredToSign: Set<FactorInstance>

		init(account: Profile.Network.Account, factorInstancesRequiredToSign: Set<FactorInstance>) {
			self.account = account
			self.factorInstancesRequiredToSign = factorInstancesRequiredToSign
		}

		// Now, before MultiFactor, this is the only public init, but once we have MultiFactor we
		// will remove this init and always use the `, factorInstancesRequiredToSign: Set<FactorInstance>` one.
		public init(account: Profile.Network.Account, factorInstanceRequiredToSign: FactorInstance) {
			precondition(account.factorInstance == factorInstanceRequiredToSign) // technically we can remove `factorInstanceRequiredToSign` but that makes logic in FactorSourceClientLive hide to much complexity that we will get once we have MultiFactor, better be prepared for MultiFactor a bit more
			self.init(account: account, factorInstancesRequiredToSign: [factorInstanceRequiredToSign])
		}
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
