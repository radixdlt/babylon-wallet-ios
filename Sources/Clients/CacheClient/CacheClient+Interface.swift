import ClientPrelude
import EngineKit

// MARK: - CacheClient
public struct CacheClient: Sendable {
	public var save: Save
	public var load: Load
	public var removeFile: RemoveFile
	public var removeFolder: RemoveFolder
	public var removeAll: RemoveAll

	init(
		save: @escaping Save,
		load: @escaping Load,
		removeFile: @escaping RemoveFile,
		removeFolder: @escaping RemoveFolder,
		removeAll: @escaping RemoveAll
	) {
		self.save = save
		self.load = load
		self.removeFile = removeFile
		self.removeFolder = removeFolder
		self.removeAll = removeAll
	}
}

extension CacheClient {
	public typealias Save = @Sendable (Encodable, Entry) -> Void
	public typealias Load = @Sendable (Decodable.Type, Entry) throws -> Decodable
	public typealias RemoveFile = @Sendable (Entry) -> Void
	public typealias RemoveFolder = @Sendable (Entry) -> Void
	public typealias RemoveAll = @Sendable () -> Void
}

extension DependencyValues {
	public var cacheClient: CacheClient {
		get { self[CacheClient.self] }
		set { self[CacheClient.self] = newValue }
	}
}

// MARK: - InvalidateCachedDecision
public enum InvalidateCachedDecision {
	case cachedIsInvalid
	case cachedIsValid
}

extension CacheClient {
	public func withCaching<Model: Codable>(
		cacheEntry: Entry,
		forceRefresh: Bool = false,
		invalidateCached: (Model) -> InvalidateCachedDecision = { _ in .cachedIsValid },
		request: () async throws -> Model
	) async throws -> Model {
		@Sendable func fetchNew() async throws -> Model {
			let model = try await request()
			save(model, cacheEntry)
			return model
		}

		if !forceRefresh, let model = try? load(Model.self, cacheEntry) as? Model {
			switch invalidateCached(model) {
			case .cachedIsInvalid:
				removeFile(cacheEntry)
				return try await fetchNew()
			case .cachedIsValid:
				return model
			}
		} else {
			return try await fetchNew()
		}
	}
}

extension CacheClient {
	public enum Entry: Equatable {
		public enum OnLedgerEntity: Hashable {
			case account(Address)
			case resource(Address)
			case resourcePool(Address)
			case validator(Address)
			case genericComponent(Address)
			case nonFungibleData(NonFungibleGlobalId)
			case nonFungibleIdPage(accountAddress: Address, resourceAddress: Address, pageCursor: String?)
			case associatedDapp(DappDefinitionAddress)
		}

		case onLedgerEntity(OnLedgerEntity)
		case networkName(_ url: String)
		case dAppMetadata(_ definitionAddress: String)
		case dAppRequestMetadata(_ definitionAddress: String)
		case rolaDappVerificationMetadata(_ definitionAddress: String)
		case rolaWellKnownFileVerification(_ url: String)

		var filesystemFilePath: String {
			switch self {
			case let .onLedgerEntity(entity):
				switch entity {
				case .account:
					return "\(filesystemFolderPath)/details"
				case let .resource(resourceAddress):
					return "\(filesystemFolderPath)/\(resourceAddress.address)"
				case let .resourcePool(resourcePoolAddress):
					return "\(filesystemFolderPath)/\(resourcePoolAddress.address)"
				case let .validator(validatorAddress):
					return "\(filesystemFolderPath)/\(validatorAddress.address)"
				case let .genericComponent(componentAddress):
					return "\(filesystemFolderPath)/\(componentAddress.address)"
				case let .nonFungibleData(nonFungibleGlobalId):
					return "\(filesystemFolderPath)/\(nonFungibleGlobalId.asStr())"
				case let .nonFungibleIdPage(_, resourceAddress, pageCursor):
					let file = "nonFungibleIds-" + resourceAddress.address + (pageCursor.map { "-\($0)" } ?? "")
					return "\(filesystemFolderPath)/\(file)"
				case let .associatedDapp(dappDefinitionAddress):
					return "\(filesystemFolderPath)/\(dappDefinitionAddress.address)"
				}
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
			case let .onLedgerEntity(entity):
				let folderRoot = "OnLedgerEntity"
				switch entity {
				case let .account(accountAddress):
					return "\(folderRoot)/accounts/\(accountAddress.address)"
				case .resource:
					return "\(folderRoot)/resources"
				case .resourcePool:
					return "\(folderRoot)/resourcePools"
				case .validator:
					return "\(folderRoot)/validators"
				case .genericComponent:
					return "\(folderRoot)/genericComponents"
				case .nonFungibleData:
					return "\(folderRoot)/nonFungiblesData"
				case let .nonFungibleIdPage(accountAddress, _, _):
					return "\(folderRoot)/accounts/\(accountAddress.address)"
				case .associatedDapp:
					return "\(folderRoot)/associatedDapps"
				}
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
			case .networkName, .onLedgerEntity:
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
