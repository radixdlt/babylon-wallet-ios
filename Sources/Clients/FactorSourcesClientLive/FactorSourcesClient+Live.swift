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
			importOlympiaFactorSource: { mnemonicWithPassphrase in
				let factorSource = try FactorSource.olympia(
					mnemonicWithPassphrase: mnemonicWithPassphrase
				)
				let privateFactorSource = try PrivateHDFactorSource(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					hdOnDeviceFactorSource: .init(factorSource: factorSource)
				)

				try await secureStorageClient.saveMnemonicForFactorSource(privateFactorSource)

				do {
					try await getProfileStore().updating { profile in
						guard !profile.factorSources.contains(where: { $0.id == factorSource.id }) else {
							throw FactorSourceAlreadyPresent()
						}
						profile.factorSources.append(factorSource)
					}
				} catch {
					// We were unlucky, failed to update Profile, thus best to undo the saving of
					// the mnemonic in keychain (if we can).
					try? await secureStorageClient.deleteMnemonicByFactorSourceID(factorSource.id)
					throw error
				}

				return factorSource.id
			}
		)
	}

	public static let liveValue = Self.live()
}

// MARK: - FactorSourceAlreadyPresent
struct FactorSourceAlreadyPresent: Swift.Error {}
