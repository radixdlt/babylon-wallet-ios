import BackupsClient
import ClientPrelude
import FactorSourcesClient
import ProfileStore

extension BackupsClient: DependencyKey {
	public typealias Value = BackupsClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable
		func importWith(
			mnemonicWithPassphrase: MnemonicWithPassphrase,
			operation: () async throws -> Void
		) async throws {
			let id = try await factorSourcesClient.addOnDeviceFactorSource(
				onDeviceMnemonicKind: .babylon,
				mnemonicWithPassphrase: mnemonicWithPassphrase
			)
			do {
				try await operation()
			} catch {
				// revert the saved mnemonic
				try? await secureStorageClient.deleteMnemonicByFactorSourceID(id)
				throw error
			}
		}

		return Self(
			loadProfileBackups: { () -> ProfileSnapshot.HeaderList? in
				do {
					let headers = try await secureStorageClient.loadProfileHeaderList()
					guard let headers else {
						return nil
					}
					// filter out header for which the related profile is not present in the keychain:
					var filteredHeaders = [ProfileSnapshot.Header]()
					for header in headers {
						guard let _ = try? await secureStorageClient.loadProfileSnapshotData(header.id) else {
							continue
						}
						filteredHeaders.append(header)
					}
					guard !filteredHeaders.isEmpty else {
						return nil
					}
					return .init(rawValue: .init(uniqueElements: filteredHeaders))
				} catch {
					assertionFailure("Corrupt Profile headers")
					loggerGlobal.critical("Corrupt Profile header: \(error.legibleLocalizedDescription)")
					// Corrupt Profile Headers, delete
					_ = try? await secureStorageClient.deleteProfileHeaderList()
					return nil
				}
			},
			importProfileSnapshot: { snapshot, mnemonicWithPassphrase in
				try await importWith(mnemonicWithPassphrase: mnemonicWithPassphrase) {
					try await getProfileStore().importProfileSnapshot(snapshot)
				}
			},
			importCloudProfile: { header, mnemonicWithPassphrase in
				try await importWith(mnemonicWithPassphrase: mnemonicWithPassphrase) {
					try await getProfileStore().importCloudProfileSnapshot(header)
				}
			},
			loadDeviceID: {
				try? await secureStorageClient.loadDeviceIdentifier()
			}
		)
	}
}
