
extension CacheClient: DependencyKey {
	public static let liveValue = Self(
		save: { encodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				let expirationDate = date.now.addingTimeInterval(entry.lifetime)
				try diskPersistenceClient.save(expirationDate, entry.expirationDateFilePath)
				try diskPersistenceClient.save(encodable, entry.filesystemFilePath)
				loggerGlobal.trace("💾 Data successfully saved to disk: \(entry)")
			} catch {
				loggerGlobal.trace("💾❌ Could not save data to disk: \(error.localizedDescription)")
			}
		},
		load: { decodable, entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient
			@Dependency(\.date) var date

			do {
				guard let expirationDate = try diskPersistenceClient.load(Date.self, entry.expirationDateFilePath) as? Date else {
					throw Error.expirationDateLoadingFailed
				}
				if date.now > expirationDate {
					loggerGlobal.debug("💾 Entry lifetime expired. Removing from disk...")
					try diskPersistenceClient.remove(entry.expirationDateFilePath)
					try diskPersistenceClient.remove(entry.filesystemFilePath)
					loggerGlobal.debug("💾 Expired entry removed from disk: \(entry)")
					throw Error.entryLifetimeExpired
				}
				let data = try diskPersistenceClient.load(decodable, entry.filesystemFilePath)
				loggerGlobal.debug("💾 Data successfully retrieved from disk: \(entry)")
				return data
			} catch {
				loggerGlobal.debug("💾❌ Could not retrieve data from disk: \(error.localizedDescription)")
				throw Error.dataLoadingFailed
			}
		},
		removeFile: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFilePath)
				loggerGlobal.debug("💾 Removed file: \(entry)")
			} catch {
				loggerGlobal.debug("💾❌ Could not delete file from disk: \(error.localizedDescription)")
			}
		},
		removeFolder: { entry in
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(entry.filesystemFolderPath)
				loggerGlobal.debug("💾 Removed folder: \(entry)")
			} catch {
				loggerGlobal.debug("💾❌ Could not delete folder from disk: \(error.localizedDescription)")
			}
		},
		removeAll: {
			@Dependency(\.diskPersistenceClient) var diskPersistenceClient

			do {
				try diskPersistenceClient.remove(Entry.root)
				loggerGlobal.debug("💾 Data successfully cleared from disk")
			} catch {
				loggerGlobal.debug("💾❌ Could not clear cached data from disk: \(error.localizedDescription)")
			}
		}
	)
}
