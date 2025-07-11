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
					entity.unsecuredControllingFactorInstance.map {
						mnemonicMissingFactorSources.contains($0.factorSourceId)
					} ?? false
				}

				func unrecoverable(_ entity: some EntityProtocol) -> Bool {
					entity.unsecuredControllingFactorInstance.map {
						unrecoverableFactorSources.contains($0.factorSourceId)
					} ?? false
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

		let derivePublicKeys: DerivePublicKeys = { request in
			let factorSourceId = request.factorSourceId
			guard let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(factorSourceID: factorSourceId, notifyIfMissing: false) else {
				loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceId)'")
				throw FailedToFindFactorSource()
			}
			return mnemonicWithPassphrase.derivePublicKeys(
				paths: request.derivationPaths,
				factorSourceId: factorSourceId
			)
		}

		return Self(
			controlledEntities: { _ in
				fatalError()
//				let sources: IdentifiedArrayOf<DeviceFactorSource> = try await {
//					// FIXME: Uh this aint pretty... but we are short on time.
//					if let overridingSnapshot = maybeOverridingSnapshot {
//						let profile = overridingSnapshot
//						return IdentifiedArrayOf(uniqueElements: profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) })
//					} else {
//						return try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
//					}
//				}()
//				return try await IdentifiedArrayOf(uniqueElements: sources.asyncMap {
//					try await entitiesControlledByFactorSource($0, maybeOverridingSnapshot)
//				})
			},
			entitiesInBadState: entitiesInBadState,
			derivePublicKeys: derivePublicKeys
		)
	}
}
