import ClientPrelude

// MARK: - CacheClient
public struct CacheClient: Sendable {
	public var saveCodable: SaveCodable
	public var loadCodable: LoadCodable
	public var removeFile: RemoveFile
	public var removeFolder: RemoveFolder
	public var removeAll: RemoveAll

	init(
		saveCodable: @escaping SaveCodable,
		loadCodable: @escaping LoadCodable,
		removeFile: @escaping RemoveFile,
		removeFolder: @escaping RemoveFolder,
		removeAll: @escaping RemoveAll
	) {
		self.saveCodable = saveCodable
		self.loadCodable = loadCodable
		self.removeFile = removeFile
		self.removeFolder = removeFolder
		self.removeAll = removeAll
	}

	public func save<Model>(_ model: Model, _ entry: Entry) async where Model: Codable {
		await saveCodable(model, entry)
	}

	public func load<Model>(_ modelType: Model.Type, _ entry: Entry) async throws -> Model? where Model: Codable {
		guard let model = try await loadCodable(Model.self, entry) else {
			return nil
		}
		guard let modelTyped = model as? Model else {
			assertionFailure("Failed to load value, expected type: \(String(describing: modelType)), but got: \(type(of: model)), value: \(model). This should probably never happen.")
			throw FailedToLoadCachedValue()
		}
		return modelTyped
	}
}

// MARK: - FailedToLoadCachedValue
struct FailedToLoadCachedValue: Swift.Error {}

extension CacheClient {
	public typealias SaveCodable = @Sendable (Codable, Entry) async -> Void
	public typealias LoadCodable = @Sendable (Codable.Type, Entry) async throws -> Codable?
	public typealias RemoveFile = @Sendable (Entry) async -> Void
	public typealias RemoveFolder = @Sendable (Entry) async -> Void
	public typealias RemoveAll = @Sendable () async -> Void
}

extension DependencyValues {
	public var cacheClient: CacheClient {
		get { self[CacheClient.self] }
		set { self[CacheClient.self] = newValue }
	}
}

extension CacheClient {
	public func withCaching<Model: Codable>(
		cacheEntry: Entry,
		forceRefresh: Bool = false,
		request: () async throws -> Model
	) async throws -> Model {
		if !forceRefresh, let model = try await load(Model.self, cacheEntry) {
			return model
		} else {
			let model = try await request()
			await save(model, cacheEntry)
			return model
		}
	}
}

extension CacheClient {
	public enum Entry: Equatable {
		case accountPortfolio(AccountQuantifier)
		case networkName(_ url: String)
		case dAppMetadata(_ definitionAddress: String)
		case dAppRequestMetadata(_ definitionAddress: String)
		case rolaDappVerificationMetadata(_ definitionAddress: String)
		case rolaWellKnownFileVerification(_ url: String)

		public enum AccountQuantifier: Equatable {
			case single(_ address: String)
			case all
		}

		var filesystemFilePath: String {
			switch self {
			case let .accountPortfolio(address):
				return "\(filesystemFolderPath)/accountPortfolio-\(address)"
			case let .networkName(url):
				return "\(filesystemFolderPath)/networkName-\(url)"
			case let .dAppMetadata(definitionAddress):
				return "\(filesystemFolderPath)/DappMetadata-\(definitionAddress)"
			case let .dAppRequestMetadata(definitionAddress):
				return "\(filesystemFolderPath)/DappRequestMetadata-\(definitionAddress)"
			case let .rolaDappVerificationMetadata(definitionAddress):
				return "\(filesystemFolderPath)/RolaDappVerificationMetadata-\(definitionAddress)"
			case let .rolaWellKnownFileVerification(url):
				return "\(filesystemFolderPath)/RolaWellKnownFileVerification-\(url)"
			}
		}

		var filesystemFolderPath: String {
			switch self {
			case .accountPortfolio:
				return "AccountPortfolio"
			case .networkName:
				return "NetworkName"
			case .dAppMetadata:
				return "DappMetadata"
			case .dAppRequestMetadata:
				return "DappRequestMetadata"
			case .rolaDappVerificationMetadata:
				return "RolaDappVerificationMetadata"
			case .rolaWellKnownFileVerification:
				return "RolaWellKnownFileVerification"
			}
		}

		var expirationDateFilePath: String {
			"\(filesystemFilePath)-expirationDate"
		}

		var lifetime: TimeInterval {
			switch self {
			case .accountPortfolio, .networkName:
				return 300
			case .dAppMetadata, .dAppRequestMetadata, .rolaDappVerificationMetadata, .rolaWellKnownFileVerification:
				return 60
			}
		}
	}

	public enum Error: Swift.Error {
		case dataLoadingFailed
		case expirationDateLoadingFailed
		case entryLifetimeExpired
	}
}

extension CacheClient {
	@Sendable
	public func clearCacheForAccounts(
		_ accounts: Set<AccountAddress> = .init()
	) async {
		if !accounts.isEmpty {
			for account in accounts {
				await removeFile(.accountPortfolio(.single(account.address)))
			}
		} else {
			await removeFolder(.accountPortfolio(.all))
		}
	}
}
