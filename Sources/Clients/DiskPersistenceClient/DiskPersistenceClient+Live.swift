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
			do {
				guard !fileManager.fileExists(atPath: url.path) else { return }
				try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
			} catch {
				throw error
			}
		}

		enum Error: Swift.Error {
			case noCachesDirectoryFound
		}

		return Self(
			save: { encodable, path in
				do {
					guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
						throw Error.noCachesDirectoryFound
					}
					try createDirectoryIfNeeded(at: url)
					let data = try JSONEncoder().encode(encodable)
					try data.write(to: url, options: .atomic)
				} catch {
					throw error
				}
			}, load: { decodable, path in
				do {
					guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
						throw Error.noCachesDirectoryFound
					}
					let data = try Data(contentsOf: url)
					let value = try JSONDecoder().decode(decodable, from: data)
					return value
				} catch {
					throw error
				}
			}, remove: { path in
				do {
					guard let url = cachesDirectoryURL?.appendingPathComponent(path) else {
						throw Error.noCachesDirectoryFound
					}
					try fileManager.removeItem(at: url)
				} catch {
					throw error
				}
			}, removeAll: {
				do {
					guard let caches = cachesDirectoryURL else {
						throw Error.noCachesDirectoryFound
					}
					let contents = try fileManager.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil, options: [])
					for fileUrl in contents {
						try fileManager.removeItem(at: fileUrl)
					}
				} catch {
					throw error
				}
			}
		)
	}
}
