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

			let (allNonHiddenEntities, allHiddenEntities) = try await { () -> (allNonHiddenEntities: [EntityPotentiallyVirtual], allHiddenEntities: [EntityPotentiallyVirtual]) in
				let accountNonHidden: [Profile.Network.Account]
				let accountHidden: [Profile.Network.Account]
				let personasNonHidden: [Profile.Network.Persona]
				let personasHidden: [Profile.Network.Persona]

				// FIXME: Uh this aint pretty... but we are short on time.
				if let overridingSnapshot = maybeSnapshot {
					let networkID = Radix.Gateway.default.network.id
					let profile = Profile(snapshot: overridingSnapshot)
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

				var allNonHiddenEntities = accountNonHidden.map(EntityPotentiallyVirtual.account)
				allNonHiddenEntities.append(contentsOf: personasNonHidden.map(EntityPotentiallyVirtual.persona))

				var allHidden = accountHidden.map(EntityPotentiallyVirtual.account)
				allHidden.append(contentsOf: personasHidden.map(EntityPotentiallyVirtual.persona))

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

		return Self(
			publicKeysFromOnDeviceHD: { request in
				let factorSourceID = request.deviceFactorSource.id

				guard
					let mnemonicWithPassphrase = try secureStorageClient
					.loadMnemonic(factorSourceID: factorSourceID, purpose: request.loadMnemonicPurpose)
				else {
					loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceID)'")
					throw FailedToFindFactorSource()
				}
				let hdRoot = try mnemonicWithPassphrase.hdRoot()
				let derivedKeys = try request.derivationPaths.map {
					let key = try hdRoot.derivePrivateKey(
						path: $0,
						curve: $0.curveForScheme
					)
					return HierarchicalDeterministicPublicKey(publicKey: key.publicKey(), derivationPath: $0)
				}
				return derivedKeys
			},
			signatureFromOnDeviceHD: { request in
				let privateKey = try request.hdRoot.derivePrivateKey(
					path: request.derivationPath,
					curve: request.curve
				)
				return try privateKey.sign(hashOfMessage: request.hashedData)
			},
			isAccountRecoveryNeeded: {
				do {
					let deviceFactorSource = try await factorSourcesClient.getFactorSources().babylonDeviceFactorSources().sorted(by: \.lastUsedOn).first

					guard
						let deviceFactorSource,
						let mnemonicWithPassphrase = try secureStorageClient
						.loadMnemonic(
							factorSourceID: deviceFactorSource.id,
							purpose: .checkingAccounts,
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
						let profile = Profile(snapshot: overridingSnapshot)
						return IdentifiedArrayOf(uniqueElements: profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) })
					} else {
						return try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
					}
				}()
				return try await IdentifiedArrayOf(uniqueElements: sources.asyncMap {
					try await entitiesControlledByFactorSource($0, maybeOverridingSnapshot)
				})
			}
		)
	}()
}
