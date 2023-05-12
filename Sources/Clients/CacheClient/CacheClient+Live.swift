import ClientPrelude
import DiskPersistenceClient

extension CacheClient: DependencyKey {
	public static let liveValue = Self(
		saveCodable: { encodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				let expirationDate = date.now.addingTimeInterval(entry.lifetime)
				try await diskPersistenceClient.save(expirationDate, entry.expirationDateFilePath)
				try await diskPersistenceClient.save(encodable, entry.filesystemFilePath)
				loggerGlobal.trace("💾 Data successfully saved to disk: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not save data to disk: \(error.localizedDescription)")
			}
		},
		loadCodable: { decodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				guard let expirationDate = try await diskPersistenceClient.load(Date.self, entry.expirationDateFilePath) as? Date else {
					throw Error.expirationDateLoadingFailed
				}
				if date.now > expirationDate {
					loggerGlobal.trace("💾 Entry lifetime expired. Removing from disk...")
					try await diskPersistenceClient.remove(entry.expirationDateFilePath)
					try await diskPersistenceClient.remove(entry.filesystemFilePath)
					loggerGlobal.trace("💾 Expired entry removed from disk: \(entry)")
					throw Error.entryLifetimeExpired
				}
				guard let data = try await diskPersistenceClient.load(decodable, entry.filesystemFilePath) else {
					return nil
				}
				loggerGlobal.trace("💾 Data successfully retrieved from disk: \(entry)")
				return data
			} catch {
				loggerGlobal.trace("💾 Could not retrieve data from disk: \(error.localizedDescription)")
				throw Error.dataLoadingFailed
			}
		},
		removeFile: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try await diskPersistenceClient.remove(entry.filesystemFilePath)
				loggerGlobal.trace("💾 Removed file: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not delete file from disk: \(error.localizedDescription)")
			}
		}, removeFolder: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try await diskPersistenceClient.remove(entry.filesystemFolderPath)
				loggerGlobal.trace("💾 Removed folder: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not delete folder from disk: \(error.localizedDescription)")
			}
		}, removeAll: {
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try await diskPersistenceClient.removeAll()
				loggerGlobal.trace("💾 Data successfully cleared from disk")
			} catch {
				loggerGlobal.warning("💾 Could not clear cached data from disk: \(error.localizedDescription)")
			}
		}
	)
}
