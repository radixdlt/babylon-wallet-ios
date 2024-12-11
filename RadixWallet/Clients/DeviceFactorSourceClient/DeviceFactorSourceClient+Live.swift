// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - DeviceFactorSourceClient + DependencyKey
extension DeviceFactorSourceClient: DependencyKey {
	typealias Value = Self

	static let liveValue: Self = .liveValue()

	static func liveValue(profileStore: ProfileStore = .shared) -> DeviceFactorSourceClient {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource = { factorSource, maybeSnapshot in
			let profileToCheck: ProfileToCheck = if let maybeSnapshot {
				.specific(maybeSnapshot)
			} else {
				.current
			}
			let result = try await SargonOS.shared.entitiesLinkedToFactorSource(factorSource: factorSource.asGeneral, profileToCheck: profileToCheck)
			guard case let .device(integrity) = result.integrity else {
				struct UnexpectedFactorSource: Error {}
				throw UnexpectedFactorSource()
			}
			return EntitiesControlledByFactorSource(
				entities: result.accounts.map(AccountOrPersona.account) + result.personas.map(AccountOrPersona.persona),
				hiddenEntities: result.hiddenAccounts.map(AccountOrPersona.account) + result.hiddenPersonas.map(AccountOrPersona.persona),
				deviceFactorSource: factorSource,
				isMnemonicPresentInKeychain: integrity.isMnemonicPresentInKeychain,
				isMnemonicMarkedAsBackedUp: integrity.isMnemonicMarkedAsBackedUp
			)
		}

		struct KeychainPresenceOfMnemonic: Sendable, Equatable {
			let id: FactorSourceIDFromHash
			let present: Bool
		}

		@Sendable
		func factorSourcesMnemonicPresence() async -> AnyAsyncSequence<[KeychainPresenceOfMnemonic]> {
			await combineLatest(profileStore.factorSourcesValues(), secureStorageClient.keychainChanged().prepend(()))
				.map { factorSources, _ in
					factorSources
						.compactMap { $0.extract(DeviceFactorSource.self)?.id }
						.map { id in
							KeychainPresenceOfMnemonic(id: id, present: secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(id))
						}
				}
				.removeDuplicates()
				.eraseToAnyAsyncSequence()
		}

		let entitiesInBadState: @Sendable () async throws -> AnyAsyncSequence<(withoutControl: AddressesOfEntitiesInBadState, unrecoverable: AddressesOfEntitiesInBadState)> = {
			await combineLatest(factorSourcesMnemonicPresence(), userDefaults.factorSourceIDOfBackedUpMnemonics(), profileStore.values()).map { presencesOfMnemonics, backedUpFactorSources, profile in

				let mnemonicMissingFactorSources = presencesOfMnemonics
					.filter(not(\.present))
					.map(\.id)

				let mnemomincPresentFactorSources = presencesOfMnemonics
					.filter(\.present)
					.map(\.id)

				let unrecoverableFactorSources = mnemomincPresentFactorSources
					.filter { !backedUpFactorSources.contains($0) }

				let network = try profile.network(id: profile.networkID)
				let accounts = network.getAccounts()
				let hiddenAccounts = network.getHiddenAccounts()
				let personas = network.getPersonas()
				let hiddenPersonas = network.getHiddenPersonas()

				func withoutControl(_ entity: some EntityProtocol) -> Bool {
					switch entity.securityState {
					case let .unsecured(value):
						mnemonicMissingFactorSources.contains(value.transactionSigning.factorSourceId)
					}
				}

				func unrecoverable(_ entity: some EntityProtocol) -> Bool {
					switch entity.securityState {
					case let .unsecured(value):
						unrecoverableFactorSources.contains(value.transactionSigning.factorSourceId)
					}
				}

				let withoutControl = AddressesOfEntitiesInBadState(
					accounts: accounts.filter(withoutControl(_:)).map(\.address),
					hiddenAccounts: hiddenAccounts.filter(withoutControl(_:)).map(\.address),
					personas: personas.filter(withoutControl(_:)).map(\.address),
					hiddenPersonas: hiddenPersonas.filter(withoutControl(_:)).map(\.address)
				)

				let unrecoverable = AddressesOfEntitiesInBadState(
					accounts: accounts.filter(unrecoverable(_:)).map(\.address),
					hiddenAccounts: hiddenAccounts.filter(unrecoverable(_:)).map(\.address),
					personas: personas.filter(unrecoverable(_:)).map(\.address),
					hiddenPersonas: hiddenPersonas.filter(unrecoverable(_:)).map(\.address)
				)

				return (withoutControl: withoutControl, unrecoverable: unrecoverable)
			}
			.eraseToAnyAsyncSequence()
		}

		return Self(
			publicKeysFromOnDeviceHD: { request in
				let factorSourceID = request.deviceFactorSource.id
				let mnemonicWithPassphrase = try request.getMnemonicWithPassphrase()
				return mnemonicWithPassphrase.derivePublicKeys(paths: request.derivationPaths)
			},
			signatureFromOnDeviceHD: { request in
				request.mnemonicWithPassphrase.sign(hash: request.hashedData, path: request.derivationPath)
			},
			isAccountRecoveryNeeded: {
				do {
					let deviceFactorSource = try await factorSourcesClient.getFactorSources().babylonDeviceFactorSources().sorted(by: \.lastUsedOn).first

					guard
						let deviceFactorSource,
						let mnemonicWithPassphrase = try secureStorageClient
						.loadMnemonic(
							factorSourceID: deviceFactorSource.id,
							notifyIfMissing: false
						)
					else {
						// Failed to find mnemonic for factor source
						return true
					}

					let accountsControlledByMainDeviceFactorSource = try await accountsClient.getAccountsOnCurrentNetwork().filter {
						$0.virtualHierarchicalDeterministicFactorInstances.contains(where: { $0.factorSourceID == deviceFactorSource.id })
					}

					do {
						let hasControlOfAllAccounts = try mnemonicWithPassphrase.validatePublicKeys(of: accountsControlledByMainDeviceFactorSource.elements)
						return !hasControlOfAllAccounts // if we dont have controll of ALL accounts, then recovery is needed.
					} catch {
						// Account recover needed
						return true
					}

				} catch {
					loggerGlobal.error("Failure during check if wallet needs account recovery: \(String(describing: error))")
					if error is KeychainAccess.Status {
						throw error
					}
					return true
				}
			},
			entitiesControlledByFactorSource: entitiesControlledByFactorSource,
			controlledEntities: { maybeOverridingSnapshot in
				let sources: IdentifiedArrayOf<DeviceFactorSource> = try await {
					// FIXME: Uh this aint pretty... but we are short on time.
					if let overridingSnapshot = maybeOverridingSnapshot {
						let profile = overridingSnapshot
						return IdentifiedArrayOf(uniqueElements: profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) })
					} else {
						return try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
					}
				}()
				return try await IdentifiedArrayOf(uniqueElements: sources.asyncMap {
					try await entitiesControlledByFactorSource($0, maybeOverridingSnapshot)
				})
			},
			entitiesInBadState: entitiesInBadState
		)
	}
}
