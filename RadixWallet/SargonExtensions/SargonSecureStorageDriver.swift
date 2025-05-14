import FirebaseCrashlytics
import KeychainAccess
import Sargon

// MARK: - SargonSecureStorage
final class SargonSecureStorage: SecureStorageDriver {
	@Dependency(\.secureStorageClient) var secureStorageClient
	let userDefaults = UserDefaults.Dependency.radix

	func loadData(key: SargonUniFFI.SecureStorageKey) async throws -> SargonUniFFI.BagOfBytes? {
		switch key {
		case .hostId:
			return loadHostId()

		case let .deviceFactorSourceMnemonic(factorSourceId):
			return try secureStorageClient.loadMnemonicDataByFactorSourceID(
				.init(
					factorSourceID: factorSourceId,
					notifyIfMissing: true
				)
			)

		case .profileSnapshot:
			guard let activeProfileId = userDefaults.getActiveProfileID() else {
				return nil
			}

			return try secureStorageClient.loadProfileSnapshotData(activeProfileId)
		}
	}

	func saveData(key: SargonUniFFI.SecureStorageKey, data: SargonUniFFI.BagOfBytes) async throws {
		switch key {
		case .hostId:
			let hostId = try newHostIdFromJsonBytes(jsonBytes: data)
			let deviceInfo = DeviceInfo(id: hostId.id, date: hostId.generatedAt)
			try secureStorageClient.saveDeviceInfo(deviceInfo)

		case let .deviceFactorSourceMnemonic(factorSourceId):
			try secureStorageClient.saveMnemonicForFactorSourceData(factorSourceId, data)

		case let .profileSnapshot(profileId):
			let activeProfileId = userDefaults.getActiveProfileID()
			func cleanupOldTemporaryProfile() {
				if let activeProfileId, activeProfileId != profileId {
					try? secureStorageClient.deleteProfile(activeProfileId)
				}
			}

			do {
				try secureStorageClient.saveProfileSnapshotData(profileId, data)
				userDefaults.setActiveProfileID(profileId)
			} catch {
				Crashlytics.crashlytics().record(error: error)
				if let err = error as? KeychainAccess.Status, err == .duplicateItem {
					// Recover from duplicateItem error
					// 1. Save the profile under new keychain key and set as active.
					loggerGlobal.info("duplicateItem - saving temp profile")
					let tempId = ProfileID()
					try secureStorageClient.saveProfileSnapshotData(tempId, data)
					userDefaults.setActiveProfileID(tempId)
					cleanupOldTemporaryProfile()
					Crashlytics.crashlytics().log("Temporary profile created and set as active")

					do {
						// 2. Delete the broken record
						try secureStorageClient.deleteProfile(profileId)
						Crashlytics.crashlytics().log("Deleted broken record")

						// 3. Recreate the original record
						try secureStorageClient.saveProfileSnapshotData(profileId, data)
						userDefaults.setActiveProfileID(profileId)
						Crashlytics.crashlytics().log("Recreated the original key, and set as active")

						// 4. Delete the temporary record
						try secureStorageClient.deleteProfile(tempId)
						Crashlytics.crashlytics().log("Deleted the temporary profile")
					} catch {
						Crashlytics.crashlytics().record(error: error)
					}
				} else {
					throw error
				}
			}
		}
	}

	func deleteDataForKey(key: SargonUniFFI.SecureStorageKey) async throws {
		switch key {
		case .hostId:
			try secureStorageClient.deleteDeviceInfo()
		case let .deviceFactorSourceMnemonic(factorSourceId):
			try secureStorageClient.deleteMnemonicByFactorSourceID(factorSourceId)
		case .profileSnapshot:
			guard let activeProfileId = userDefaults.getActiveProfileID() else {
				return
			}
			userDefaults.removeActiveProfileID()
			try secureStorageClient.deleteProfileAndMnemonicsByFactorSourceIDs(
				profileID: activeProfileId,
				keepInICloudIfPresent: true
			)
		}
	}

	func containsDataForKey(key: SargonUniFFI.SecureStorageKey) async throws -> Bool {
		try secureStorageClient.containsDataForKey(key)
	}

	private func loadHostId() -> BagOfBytes? {
		let deviceInfo: DeviceInfo? = {
			if let existing = try? secureStorageClient.loadDeviceInfo() {
				return existing
			}

			if let legacyDeviceID = try? secureStorageClient.deprecatedLoadDeviceID() {
				let deviceInfo = DeviceInfo(id: legacyDeviceID, date: .now)
				try? secureStorageClient.saveDeviceInfo(deviceInfo)
				secureStorageClient.deleteDeprecatedDeviceID()
				return deviceInfo
			}

			return nil

		}()

		if let deviceInfo {
			let hostId = HostId(id: deviceInfo.id, generatedAt: deviceInfo.date)
			return hostIdToJsonBytes(hostId: hostId)
		}

		return nil
	}
}
