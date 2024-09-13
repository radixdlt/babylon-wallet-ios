import Sargon

// MARK: - SargonSecureStorage
final class SargonSecureStorage: SecureStorageDriver {
	@Dependency(\.secureStorageClient) var secureStorageClient
	let userDefaults = UserDefaults.Dependency.radix

	func loadData(key: SargonUniFFI.SecureStorageKey) async throws -> SargonUniFFI.BagOfBytes? {
		switch key {
		case .hostId:
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
				return try? JSONEncoder().encode(hostId)
			}

			return nil

		case let .deviceFactorSourceMnemonic(factorSourceId):
			return try secureStorageClient.loadMnemonicDataByFactorSourceID(.init(factorSourceID: factorSourceId, notifyIfMissing: true))

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
			let hostId = try JSONDecoder().decode(HostId.self, from: data)
			let deviceInfo = DeviceInfo(id: hostId.id, date: hostId.generatedAt)
			try secureStorageClient.saveDeviceInfo(deviceInfo)

		case let .deviceFactorSourceMnemonic(factorSourceId):
			try secureStorageClient.saveMnemonicForFactorSourceData(factorSourceId, data)

		case .profileSnapshot:
			if let activeProfileId = userDefaults.getActiveProfileID() {
				try secureStorageClient.saveProfileSnapshotData(activeProfileId, data)
				return
			}

			let json = String(data: data, encoding: .utf8)!
			let profile = try Profile(jsonString: json)

			try secureStorageClient.saveProfileSnapshotData(profile.id, data)

			userDefaults.setActiveProfileID(profile.id)
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
}

// MARK: - HostId + Codable
extension HostId: Codable {
	enum CodingKeys: String, CodingKey {
		case id
		case generatedAt = "generated_at"
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(generatedAt, forKey: .generatedAt)
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			id: container.decode(DeviceId.self, forKey: .id),
			generatedAt: container.decode(Timestamp.self, forKey: .generatedAt)
		)
	}
}
