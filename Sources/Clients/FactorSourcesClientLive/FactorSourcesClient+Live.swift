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
			getFactorsOfSigners: { accountAddresses in
				var factorsOfSigners: Set<FactorsOfSigner> = []
				var factorSources: Set<FactorSource> = []

				for address in accountAddresses {
					fatalError()
				}

				return FactorsOfSigners(
					factorsOfSigners: factorsOfSigners,
					factorSources: factorSources
				)
			}
		)
	}

	public static let liveValue = Self.live()
}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}
