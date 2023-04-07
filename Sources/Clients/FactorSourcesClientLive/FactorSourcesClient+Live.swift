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
		return Self(
			getFactorSources: {
				await getProfileStore().profile.factorSources
			},
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
			}
		)
	}

	public static let liveValue = Self.live()
}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}
