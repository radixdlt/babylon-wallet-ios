import ClientPrelude
import OnboardingClient
import ProfileStore

extension OnboardingClient: DependencyKey {
	public typealias Value = OnboardingClient

	public static let liveValue = Self.live()

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.userDefaultsClient) var userDefaultsClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			loadProfile: {
				await getProfileStore().getLoadProfileOutcome()
			},
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
			importProfileSnapshot: {
				try await getProfileStore().importProfileSnapshot($0)
			},
			importCloudProfile: { header in
				try await getProfileStore().importCloudProfileSnapshot(header)
			},
			commitEphemeral: {
				try await getProfileStore().commitEphemeral()
			},
			loadDeviceID: {
				try? await secureStorageClient.loadDeviceIdentifier()
			}
		)
	}
}
