import ClientPrelude
import DiskPersistenceClient

extension CacheClient: DependencyKey {
	public static let liveValue = Self(
		save: { encodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				let expirationDate = date.now.addingTimeInterval(entry.lifetime)
				try diskPersistenceClient.save(expirationDate, entry.expirationDateFilePath)
				try diskPersistenceClient.save(encodable, entry.filesystemFilePath)
				loggerGlobal.info("💾 Data successfully saved to disk: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not save data to disk: \(error.localizedDescription)")
			}
		}, load: { decodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				guard let expirationDate = try diskPersistenceClient.load(Date.self, entry.expirationDateFilePath) as? Date else {
					throw Error.expirationDateLoadingFailed
				}
				if date.now > expirationDate {
					loggerGlobal.info("💾 Entry lifetime expired. Removing from disk...")
					try diskPersistenceClient.remove(entry.expirationDateFilePath)
					try diskPersistenceClient.remove(entry.filesystemFilePath)
					loggerGlobal.info("💾 Expired entry removed from disk: \(entry)")
					throw Error.entryLifetimeExpired
				}
				let data = try diskPersistenceClient.load(decodable, entry.filesystemFilePath)
				loggerGlobal.info("💾 Data successfully retrieved from disk: \(entry)")
				return data
			} catch {
				// Clear corrupt data
				try? diskPersistenceClient.remove(entry.filesystemFilePath)
				loggerGlobal.warning("💾 Could not retrieve data from disk: \(error.localizedDescription)")
				throw Error.dataLoadingFailed
			}
		}, removeFile: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFilePath)
				loggerGlobal.info("💾 Removed file: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not delete file from disk: \(error.localizedDescription)")
			}
		}, removeFolder: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFolderPath)
				loggerGlobal.info("💾 Removed folder: \(entry)")
			} catch {
				loggerGlobal.warning("💾 Could not delete folder from disk: \(error.localizedDescription)")
			}
		}, removeAll: {
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.removeAll()
				loggerGlobal.info("💾 Data successfully cleared from disk")
			} catch {
				loggerGlobal.warning("💾 Could not clear cached data from disk: \(error.localizedDescription)")
			}
		}
	)
}
