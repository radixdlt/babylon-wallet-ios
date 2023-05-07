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
	public var updateLastUsed: UpdateLastUsed

	public init(
		getFactorSources: @escaping GetFactorSources,
		factorSourcesAsyncSequence: @escaping FactorSourcesAsyncSequence,
		addPrivateHDFactorSource: @escaping AddPrivateHDFactorSource,
		checkIfHasOlympiaFactorSourceForAccounts: @escaping CheckIfHasOlympiaFactorSourceForAccounts,
		addOffDeviceFactorSource: @escaping AddOffDeviceFactorSource,
		getSigningFactors: @escaping GetSigningFactors,
		updateLastUsed: @escaping UpdateLastUsed
	) {
		self.getFactorSources = getFactorSources
		self.factorSourcesAsyncSequence = factorSourcesAsyncSequence
		self.addPrivateHDFactorSource = addPrivateHDFactorSource
		self.checkIfHasOlympiaFactorSourceForAccounts = checkIfHasOlympiaFactorSourceForAccounts
		self.addOffDeviceFactorSource = addOffDeviceFactorSource
		self.getSigningFactors = getSigningFactors
		self.updateLastUsed = updateLastUsed
	}
}

// MARK: FactorSourcesClient.GetFactorSources
extension FactorSourcesClient {
	public typealias GetFactorSources = @Sendable () async throws -> FactorSources
	public typealias FactorSourcesAsyncSequence = @Sendable () async -> AnyAsyncSequence<FactorSources>
	public typealias AddPrivateHDFactorSource = @Sendable (PrivateHDFactorSource) async throws -> FactorSourceID
	public typealias CheckIfHasOlympiaFactorSourceForAccounts = @Sendable (NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) async -> FactorSourceID?
	public typealias AddOffDeviceFactorSource = @Sendable (FactorSource) async throws -> Void
	public typealias GetSigningFactors = @Sendable (NetworkID, NonEmpty<Set<Signer.Entity>>) async throws -> SigningFactors
	public typealias UpdateLastUsed = @Sendable (UpdateFactorSourceLastUsedRequest) async throws -> Void
}

public typealias SigningFactors = OrderedDictionary<FactorSourceKind, NonEmpty<Set<SigningFactor>>>

extension SigningFactors {
	public var signerCount: Int {
		values.flatMap { $0.map(\.signers.count) }.reduce(0, +)
	}
}

extension FactorSourcesClient {
	public func getFactorSource(
		id: FactorSourceID,
		matching filter: @escaping (FactorSource) -> Bool = { _ in true }
	) async throws -> FactorSource? {
		try await getFactorSources(matching: filter)[id: id]
	}

	public func getFactorSource(
		id: FactorSourceID,
		ensureKind kind: FactorSourceKind
	) async throws -> FactorSource? {
		try await getFactorSource(id: id) { $0.kind == kind }
	}

	public func getFactorSource(
		of factorInstance: FactorInstance
	) async throws -> FactorSource? {
		try await getFactorSource(id: factorInstance.factorSourceID)
	}

	public func getFactorSources(
		matching filter: (FactorSource) -> Bool
	) async throws -> IdentifiedArrayOf<FactorSource> {
		try await IdentifiedArrayOf(uniqueElements: getFactorSources().filter(filter))
	}

	public func getFactorSources(
		ofKind kind: FactorSourceKind
	) async throws -> IdentifiedArrayOf<FactorSource> {
		try await getFactorSources(matching: { $0.kind == kind })
	}
}

// MARK: - UpdateFactorSourceLastUsedRequest
public struct UpdateFactorSourceLastUsedRequest: Sendable, Hashable {
	public let factorSourceIDs: [FactorSource.ID]
	public let lastUsedOn: Date
	public let usagePurpose: FactorSource.UsagePurpose
	public init(
		factorSourceIDs: [FactorSource.ID],
		usagePurpose: FactorSource.UsagePurpose,
		lastUsedOn: Date = .init()
	) {
		self.factorSourceIDs = factorSourceIDs
		self.usagePurpose = usagePurpose
		self.lastUsedOn = lastUsedOn
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
