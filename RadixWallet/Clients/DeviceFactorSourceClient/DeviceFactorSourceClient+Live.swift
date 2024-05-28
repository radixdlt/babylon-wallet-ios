// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - DeviceFactorSourceClient + DependencyKey
extension DeviceFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.personasClient) var personasClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource = { factorSource, maybeSnapshot in

			let (allNonHiddenEntities, allHiddenEntities) = try await { () -> (allNonHiddenEntities: [AccountOrPersona], allHiddenEntities: [AccountOrPersona]) in
				let accountNonHidden: [Account]
				let accountHidden: [Account]
				let personasNonHidden: [Persona]
				let personasHidden: [Persona]

				if let overridingSnapshot = maybeSnapshot {
					let networkID = NetworkID.mainnet
					let profile = overridingSnapshot
					let network = try profile.network(id: networkID)
					accountNonHidden = network.getAccounts().elements
					personasNonHidden = network.getPersonas().elements

					accountHidden = network.getHiddenAccounts().elements
					personasHidden = network.getHiddenPersonas().elements
				} else {
					accountNonHidden = try await accountsClient.getAccountsOnCurrentNetwork().elements
					personasNonHidden = try await personasClient.getPersonas().elements

					accountHidden = try await accountsClient.getHiddenAccountsOnCurrentNetwork().elements
					personasHidden = try await personasClient.getHiddenPersonasOnCurrentNetwork().elements
				}

				var allNonHiddenEntities = accountNonHidden.map(AccountOrPersona.account)
				allNonHiddenEntities.append(contentsOf: personasNonHidden.map(AccountOrPersona.persona))

				var allHidden = accountHidden.map(AccountOrPersona.account)
				allHidden.append(contentsOf: personasHidden.map(AccountOrPersona.persona))

				return (allNonHiddenEntities, allHidden)
			}()

			let nonHiddenEntitiesForSource = allNonHiddenEntities.filter { entity in
				switch entity.securityState {
				case let .unsecured(unsecuredEntityControl):
					unsecuredEntityControl.transactionSigning.factorSourceID == factorSource.id
				}
			}

			let hiddenEntitiesForSource = allHiddenEntities.filter { entity in
				switch entity.securityState {
				case let .unsecured(unsecuredEntityControl):
					unsecuredEntityControl.transactionSigning.factorSourceID == factorSource.id
				}
			}

			let isMnemonicMarkedAsBackedUp = userDefaults.getFactorSourceIDOfBackedUpMnemonics().contains(factorSource.id)

			return EntitiesControlledByFactorSource(
				entities: nonHiddenEntitiesForSource,
				hiddenEntities: hiddenEntitiesForSource,
				deviceFactorSource: factorSource,
				isMnemonicPresentInKeychain: secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(factorSource.id),
				isMnemonicMarkedAsBackedUp: isMnemonicMarkedAsBackedUp
			)
		}

		let missingMnemonicEntities: @Sendable () async throws -> (accounts: [AccountAddress], personas: [IdentityAddress]) = {
			let deviceFactorSources = try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
			let entities = try await deviceFactorSources.asyncMap {
				try await entitiesControlledByFactorSource($0, nil)
			}

			var accounts: [AccountAddress] = []
			var personas: [IdentityAddress] = []
			for entity in entities {
				if !entity.isMnemonicPresentInKeychain {
					accounts.append(contentsOf: entity.accounts.map(\.address))
					accounts.append(contentsOf: entity.hiddenAccounts.map(\.address))
					personas.append(contentsOf: entity.personas.map(\.address))
					personas.append(contentsOf: entity.hiddenPersonas.map(\.address))
				}
			}
			return (accounts, personas)
		}

		let unrecoverableEntities: @Sendable () async throws -> (accounts: [AccountAddress], personas: [IdentityAddress]) = {
			let deviceFactorSources = try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
			let entities = try await deviceFactorSources.asyncMap {
				try await entitiesControlledByFactorSource($0, nil)
			}
			var accounts: [AccountAddress] = []
			var personas: [IdentityAddress] = []
			for entity in entities {
				if !entity.isMnemonicMarkedAsBackedUp {
					accounts.append(contentsOf: entity.accounts.map(\.address))
					accounts.append(contentsOf: entity.hiddenAccounts.map(\.address))
					personas.append(contentsOf: entity.personas.map(\.address))
					personas.append(contentsOf: entity.hiddenPersonas.map(\.address))
				}
			}
			return (accounts, personas)
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
			missingMnemonicEntities: missingMnemonicEntities,
			unrecoverableEntities: unrecoverableEntities
		)
	}()
}
