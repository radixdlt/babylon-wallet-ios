import AccountsClient
import ClientPrelude
import FactorSourcesClient
import ProfileStore

// MARK: - FactorSourcesClient + DependencyKey
extension FactorSourcesClient: DependencyKey {
	public typealias Value = FactorSourcesClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.secureStorageClient) var secureStorageClient

		let getFactorSources: GetFactorSources = {
			await getProfileStore().profile.factorSources
		}

		let addOffDeviceFactorSource: AddOffDeviceFactorSource = { source in
			try await getProfileStore().updating { profile in
				guard !profile.factorSources.contains(where: { $0.id == source.id }) else {
					throw FactorSourceAlreadyPresent()
				}
				profile.factorSources.append(source)
			}
		}

		return Self(
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await getProfileStore().factorSourcesValues()
			},
			addPrivateHDFactorSource: { privateFactorSource in

				try await secureStorageClient.saveMnemonicForFactorSource(privateFactorSource)
				let factorSourceID = privateFactorSource.hdOnDeviceFactorSource.factorSource.id
				do {
					try await addOffDeviceFactorSource(privateFactorSource.hdOnDeviceFactorSource.factorSource)
				} catch {
					// We were unlucky, failed to update Profile, thus best to undo the saving of
					// the mnemonic in keychain (if we can).
					try? await secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceID)
					throw error
				}

				return factorSourceID
			},
			checkIfHasOlympiaFactorSourceForAccounts: { softwareAccounts in
				guard softwareAccounts.allSatisfy({ $0.accountType == .software }) else {
					assertionFailure("Unexpectedly received hardware account, unable to verify.")
					return nil
				}
				do {
					let factorSourceIDs = try await getFactorSources()
						.filter { $0.kind == .device && $0.supportsOlympia }
						.map(\.id)

					for factorSourceID in factorSourceIDs {
						guard let mnemonic = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .importOlympiaAccounts) else {
							continue
						}
						guard try mnemonic.validatePublicKeysOf(softwareAccounts: softwareAccounts) else {
							continue
						}
						// YES Managed to validate all software accounts against existing factor source
						loggerGlobal.debug("Existing factor source found for selected Olympia software accounts.")
						return factorSourceID
					}

					return nil // failed to find any factor source
				} catch {
					loggerGlobal.warning("Failed to check if olympia factor source exists, error: \(error)")
					return nil // failure
				}
			},
			addOffDeviceFactorSource: addOffDeviceFactorSource,
			getSigningFactors: { _, accounts in
				@Dependency(\.accountsClient) var accountsClient

				let allFactorSources = try await getFactorSources()

				var signingFactors: [FactorSource: SigningFactorRef] = [:]

				for account in accounts {
					switch account.securityState {
					case let .unsecured(unsecuredEntityControl):
						let factorInstance = unsecuredEntityControl.genesisFactorInstance
						let id = factorInstance.factorSourceID
						guard let factorSource = allFactorSources[id: id] else {
							assertionFailure("Bad! factor source not found")
							throw FactorSourceNotFound()
						}
						let outerRef = signingFactors[factorSource, default: SigningFactorRef(factorSource: factorSource)]
						let innerRef = outerRef.signers[account.id, default: .init(account: account)]
						innerRef.factorInstancesRequiredToSign.insert(factorInstance)
						outerRef.signers[account.id] = innerRef
						signingFactors[factorSource] = outerRef
					}
				}

				var signingFactorsRefsByKind = OrderedDictionary<FactorSourceKind, SigningFactorsOfKindRef>()

				for (factorSource, signingFactorRef) in signingFactors {
					if let ref = signingFactorsRefsByKind[factorSource.kind] {
						try ref.add(signingFactorRef)
					} else {
						signingFactorsRefsByKind[factorSource.kind] = .init(signingFactor: signingFactorRef)
					}
				}

				var signingFactorsOfKind: OrderedDictionary<FactorSourceKind, NonEmpty<OrderedSet<SigningFactor>>> = [:]

				for (factorSourceKind, signingFactorsOfKindRef) in signingFactorsRefsByKind {
					signingFactorsOfKind[factorSourceKind] = try signingFactorsOfKindRef.valueType()
				}

				return signingFactorsOfKind
			}
		)
	}

	public static let liveValue = Self.live()
}

// MARK: - SigningFactorRef
final class SigningFactorRef: Equatable, Hashable {
	static func == (lhs: SigningFactorRef, rhs: SigningFactorRef) -> Bool {
		lhs.uuid == rhs.uuid
	}

	let uuid = UUID()
	func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
	}

	let factorSource: FactorSource
	var signers: [Profile.Network.Account.ID: SignerRef] = [:]
	init(factorSource: FactorSource, signers: [Profile.Network.Account.ID: SignerRef] = [:]) {
		self.factorSource = factorSource
		self.signers = signers
	}

	func valueType() throws -> SigningFactor {
		guard let signersNonEmpty = NonEmpty<Set<SigningFactor.Signer>>(rawValue: Set(self.signers.values.map { $0.valueType() })) else {
			throw SignersUnexpectedlyEmpty()
		}
		return .init(factorSource: factorSource, signers: signersNonEmpty)
	}
}

// MARK: - SignerRef
final class SignerRef {
	let account: Profile.Network.Account
	var factorInstancesRequiredToSign: Set<FactorInstance>
	init(account: Profile.Network.Account, factorInstancesRequiredToSign: Set<FactorInstance> = .init()) {
		self.account = account
		self.factorInstancesRequiredToSign = factorInstancesRequiredToSign
	}

	func valueType() -> SigningFactor.Signer {
		.init(account: account, factorInstancesRequiredToSign: factorInstancesRequiredToSign)
	}
}

// MARK: - SigningFactorsOfKindRef
final class SigningFactorsOfKindRef {
	private var factors: OrderedSet<SigningFactorRef>
	func valueType() throws -> NonEmpty<OrderedSet<SigningFactor>> {
		let valuesTypes = try factors.map { try $0.valueType() }
		guard let nonEmpty = NonEmpty<OrderedSet<SigningFactor>>(rawValue: OrderedSet(valuesTypes.sorted())) else {
			throw SignersUnexpectedlyEmpty()
		}
		return nonEmpty
	}

	init(signingFactor: SigningFactorRef) {
		factors = [signingFactor]
	}

	func add(_ signingFactorRef: SigningFactorRef) throws {
		let (insert, _) = self.factors.append(signingFactorRef)
		guard insert else {
			struct SigningFactorRefUnexpectedelyAlreadyPresent: Error {}
			throw SigningFactorRefUnexpectedelyAlreadyPresent()
		}
	}
}

// MARK: - MixedFactorSourceKind
struct MixedFactorSourceKind: Error {}

// MARK: - SignersUnexpectedlyEmpty
struct SignersUnexpectedlyEmpty: Error {}

// MARK: - FailedToFindSigners
struct FailedToFindSigners: Error {}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}

// MARK: - FactorSourceNotFound
struct FactorSourceNotFound: Swift.Error {}

// MARK: - SigningFactor + Comparable
extension SigningFactor: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.factorSource.kind.signingOrder < rhs.factorSource.kind.signingOrder
	}
}

extension FactorSourceKind {
	fileprivate var signingOrder: Int {
		switch self {
		case .ledgerHQHardwareWallet: return 0
		case .device: return 1
		default: return 1000
		}
	}
}
