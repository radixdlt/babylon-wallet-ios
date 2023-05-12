import ClientPrelude

// MARK: - DiskPersistenceClient + DependencyKey
extension DiskPersistenceClient: DependencyKey {
	final actor FileManagerActor: Sendable {
		private let fileManager: FileManager
		init() {
			self.fileManager = .init()
		}

		var cachesDirectoryURL: URL? {
			fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
		}

		enum Error: Swift.Error {
			case noCachesDirectoryFound
		}

		func createDirectoryIfNeeded(at url: URL) throws {
			guard !fileManager.fileExists(atPath: url.path) else { return }
			try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		}

		func save(_ encodable: Codable, _ path: String) throws {
			guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
				throw Error.noCachesDirectoryFound
			}
			try createDirectoryIfNeeded(at: url)
			let data = try JSONEncoder().encode(encodable)
			try data.write(to: url, options: .atomic)
		}

		func load(_ decodable: Codable.Type, _ path: String) throws -> Codable? {
			guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
				throw Error.noCachesDirectoryFound
			}
			let data = try Data(contentsOf: url)
			guard !data.isEmpty else { return nil } // regard empty data as `nil`.
			let value = try JSONDecoder().decode(decodable, from: data)
			return value
		}

		func remove(_ path: String) throws {
			guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
				throw Error.noCachesDirectoryFound
			}
			try fileManager.removeItem(at: url)
		}

		func removeAll() throws {
			guard let caches = cachesDirectoryURL else {
				throw Error.noCachesDirectoryFound
			}
			let contents = try fileManager.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil, options: [])
			for fileUrl in contents {
				try fileManager.removeItem(at: fileUrl)
			}
		}
	}

//	public static func live(_ fileManager: FileManager = .default) -> Self {
	//	}

	public static let liveValue = Self.live(fileManagerActor: FileManagerActor())
	internal static func live(fileManagerActor: FileManagerActor) -> Self {
		let actor = FileManagerActor()

		return Self(
			save: { try await actor.save($0, $1) },
			load: { try await actor.load($0, $1) },
			remove: { try await actor.remove($0) },
			removeAll: { try await actor.removeAll() }
		)
	}
}
