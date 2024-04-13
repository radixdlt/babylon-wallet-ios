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

		let entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource = { factorSource, _ in

			let (allNonHiddenEntities, allHiddenEntities) = try await { () -> (allNonHiddenEntities: [AccountOrPersona], allHiddenEntities: [AccountOrPersona]) in
				let accountNonHidden: [Sargon.Account]
				let accountHidden: [Sargon.Account]
				let personasNonHidden: [Persona]
				let personasHidden: [Persona]

				// FIXME: Uh this aint pretty... but we are short on time.
//				if let overridingSnapshot = maybeSnapshot {
//					let networkID = Gateway.default.network.id
//					let profile = Profile(snapshot: overridingSnapshot)
//					let network = try profile.network(id: networkID)
//					accountNonHidden = network.getAccounts().elements
//					personasNonHidden = network.getPersonas().elements
//
//					accountHidden = network.getHiddenAccounts().elements
//					personasHidden = network.getHiddenPersonas().elements
//				} else {
//					accountNonHidden = try await accountsClient.getAccountsOnCurrentNetwork().elements
//					personasNonHidden = try await personasClient.getPersonas().elements
//
//					accountHidden = try await accountsClient.getHiddenAccountsOnCurrentNetwork().elements
//					personasHidden = try await personasClient.getHiddenPersonasOnCurrentNetwork().elements
//				}

//				var allNonHiddenEntities = accountNonHidden.map(AccountOrPersona.account)
//				allNonHiddenEntities.append(contentsOf: personasNonHidden.map(AccountOrPersona.persona))
//
//				var allHidden = accountHidden.map(AccountOrPersona.account)
//				allHidden.append(contentsOf: personasHidden.map(AccountOrPersona.persona))
//
//				return (allNonHiddenEntities, allHidden)

				sargonProfileFinishMigrateAtEndOfStage1()
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
			publicKeysFromOnDeviceHD: { _ in
//				let factorSourceID = request.deviceFactorSource.id
//				let mnemonicWithPassphrase = try request.getMnemonicWithPassphrase()
//				let bip39Root = try mnemonicWithPassphrase.toSeed()
//				let derivedKeys = try request.derivationPaths.map {
//					let key = try bip39Root.derivePrivateKey(
//						path: $0,
//						curve: $0.curveForScheme
//					)
//					return HierarchicalDeterministicPublicKey(publicKey: key.publicKey(), derivationPath: $0)
//				}
//				return derivedKeys
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			signatureFromOnDeviceHD: { _ in
//				let privateKey = try request.hdRoot.derivePrivateKey(
//					path: request.derivationPath,
//					curve: request.curve
//				)
//				return try privateKey.sign(hashOfMessage: request.hashedData)
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			isAccountRecoveryNeeded: {
				/*
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
				  */
				sargonProfileFinishMigrateAtEndOfStage1()
			},
			entitiesControlledByFactorSource: entitiesControlledByFactorSource,
			controlledEntities: { _ in
//				let sources: IdentifiedArrayOf<DeviceFactorSource> = try await {
//					// FIXME: Uh this aint pretty... but we are short on time.
//					if let overridingSnapshot = maybeOverridingSnapshot {
//						let profile = Profile(snapshot: overridingSnapshot)
//						return IdentifiedArrayOf(uniqueElements: profile.factorSources.compactMap { $0.extract(DeviceFactorSource.self) })
//					} else {
//						return try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self)
//					}
//				}()
//				return try await IdentifiedArrayOf(uniqueElements: sources.asyncMap {
//					try await entitiesControlledByFactorSource($0, maybeOverridingSnapshot)
//				})
				sargonProfileFinishMigrateAtEndOfStage1()
			}
		)
	}()
}
