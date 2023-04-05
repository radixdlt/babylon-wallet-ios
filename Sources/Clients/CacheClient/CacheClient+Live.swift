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
				loggerGlobal.debug("💾 Data successfully saved to disk: \(entry)")
			} catch {
				loggerGlobal.error("💾 Could not save data to disk: \(error.localizedDescription)")
			}
		}, load: { decodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				guard let expirationDate = try diskPersistenceClient.load(Date.self, entry.expirationDateFilePath) as? Date else {
					throw Error.loadFailed
				}
				if date.now > expirationDate {
					loggerGlobal.debug("💾 Entry lifetime expired. Removing from disk...")
					try diskPersistenceClient.remove(entry.expirationDateFilePath)
					try diskPersistenceClient.remove(entry.filesystemFilePath)
					loggerGlobal.debug("💾 Expired entry removed from disk: \(entry)")
					throw Error.loadFailed
				}
				let data = try diskPersistenceClient.load(decodable, entry.filesystemFilePath)
				loggerGlobal.debug("💾 Data successfully retrieved from disk: \(entry)")
				return data
			} catch {
				loggerGlobal.error("💾 Could not retrieve data from disk: \(error.localizedDescription)")
				throw Error.loadFailed
			}
		}, removeFile: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFilePath)
				loggerGlobal.debug("💾 Removed file: \(entry)")
			} catch {
				loggerGlobal.error("💾 Could not delete file from disk: \(error.localizedDescription)")
			}
		}, removeFolder: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFolderPath)
				loggerGlobal.debug("💾 Removed folder: \(entry)")
			} catch {
				loggerGlobal.error("💾 Could not delete folder from disk: \(error.localizedDescription)")
			}
		}, removeAll: {
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.removeAll()
				loggerGlobal.debug("💾 Data successfully cleared from disk")
			} catch {
				loggerGlobal.error("💾 Could not clear cached data from disk: \(error.localizedDescription)")
			}
		}
	)
}
