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
			try secureStorageClient.saveProfileSnapshotData(profileId, data)
			userDefaults.setActiveProfileID(profileId)
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
