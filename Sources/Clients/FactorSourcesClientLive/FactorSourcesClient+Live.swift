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

		return Self(
			getFactorSources: getFactorSources,
			factorSourcesAsyncSequence: {
				await getProfileStore().factorSourcesValues()
			},
			addPrivateHDFactorSource: { privateFactorSource in

				try await secureStorageClient.saveMnemonicForFactorSource(privateFactorSource)
				let factorSourceID = privateFactorSource.hdOnDeviceFactorSource.factorSource.id
				do {
					try await getProfileStore().updating { profile in
						guard !profile.factorSources.contains(where: { $0.id == factorSourceID }) else {
							throw FactorSourceAlreadyPresent()
						}
						profile.factorSources.append(privateFactorSource.hdOnDeviceFactorSource.factorSource)
					}
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
					return false
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
						return true
					}

					return false // failed to find any factor source
				} catch {
					loggerGlobal.warning("Failed to check if olympia factor source exists, error: \(error)")
					return false // faulure
				}
			}
		)
	}

	public static let liveValue = Self.live()
}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}
