import ClientPrelude

// MARK: - DiskPersistenceClient + DependencyKey
extension DiskPersistenceClient: DependencyKey {
	public static let liveValue = live(.default)

	public static func live(_ fileManager: FileManager = .default) -> Self {
		var cachesDirectoryURL: URL? {
			fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		}

		@Sendable
		func createDirectoryIfNeeded(at url: URL) throws {
			guard !fileManager.fileExists(atPath: url.path) else { return }
			try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		}

		enum Error: Swift.Error {
			case noCachesDirectoryFound
		}

		return Self(
			save: { encodable, path in
				guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
					throw Error.noCachesDirectoryFound
				}
				try createDirectoryIfNeeded(at: url)
				let data = try JSONEncoder().encode(encodable)
				try data.write(to: url, options: .atomic)
			}, load: { decodable, path in
				guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
					throw Error.noCachesDirectoryFound
				}
				let data = try Data(contentsOf: url)
				let value = try JSONDecoder().decode(decodable, from: data)
				return value
			}, remove: { path in
				guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
					throw Error.noCachesDirectoryFound
				}
				try fileManager.removeItem(at: url)
			}, removeAll: {
				guard let caches = cachesDirectoryURL else {
					throw Error.noCachesDirectoryFound
				}
				let contents = try fileManager.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil, options: [])
				for fileUrl in contents {
					try fileManager.removeItem(at: fileUrl)
				}
			}
		)
	}
}
