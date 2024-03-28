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
		public init(address: some AddressProtocol) {
			self = .onLedgerEntity(.address(address.embed()))
		}

		public enum OnLedgerEntity: Hashable {
			case address(Address)

			case nonFungibleData(NonFungibleGlobalId)
			case nonFungibleIdPage(
				accountAddress: AccountAddress,
				resourceAddress: ResourceAddress,
				pageCursor: String?
			)

			var filesystemFilePath: String {
				//				switch entity {
				//				case .account:
				//					return "\(filesystemFolderPath)/details"
				//				case let .resource(resourceAddress):
				//					return "\(filesystemFolderPath)/\(resourceAddress.address)"
				//				case let .resourcePool(resourcePoolAddress):
				//					return "\(filesystemFolderPath)/\(resourcePoolAddress.address)"
				//				case let .validator(validatorAddress):
				//					return "\(filesystemFolderPath)/\(validatorAddress.address)"
				//				case let .componentAddress(componentAddress):
				//					return "\(filesystemFolderPath)/\(componentAddress.address)"
				//				case let .nonFungibleData(nonFungibleGlobalId):
				//					return "\(filesystemFolderPath)/\(nonFungibleGlobalId.description)"
				//				case let .nonFungibleIdPage(_, resourceAddress, pageCursor):
				//					let file = "nonFungibleIds-" + resourceAddress.address + (pageCursor.map { "-\($0)" } ?? "")
				//					return "\(filesystemFolderPath)/\(file)"
				//				}
				fatalError()
			}

			var filesystemFolderPath: String {
//				let folderRoot = "OnLedgerEntity"
//				switch entity {
//				case let .account(accountAddress):
//					return "\(folderRoot)/accounts/\(accountAddress.address)"
//				case .resource:
//					return "\(folderRoot)/resources"
//				case .resourcePool:
//					return "\(folderRoot)/resourcePools"
//				case .validator:
//					return "\(folderRoot)/validators"
//				case .componentAddress:
//					return "\(folderRoot)/componentAddress"
//				case .nonFungibleData:
//					return "\(folderRoot)/nonFungiblesData"
//				case let .nonFungibleIdPage(accountAddress, _, _):
//					return "\(folderRoot)/accounts/\(accountAddress.address)"
//				}
				fatalError()
			}
		}

		case onLedgerEntity(OnLedgerEntity)
		case networkName(_ url: String)
		case dAppRequestMetadata(_ definitionAddress: String)
		case rolaDappVerificationMetadata(_ definitionAddress: String)
		case rolaWellKnownFileVerification(_ url: String)
		case tokenPrices(_ currency: FiatCurrency)
		case dateOfFirstTransaction(_ accountAddress: AccountAddress)

		var filesystemFilePath: String {
			switch self {
			case let .onLedgerEntity(entity):
				entity.filesystemFilePath
			case let .networkName(url):
				"\(filesystemFolderPath)/networkName-\(url)"
			case let .dAppRequestMetadata(definitionAddress):
				"\(filesystemFolderPath)/DappRequestMetadata-\(definitionAddress)"
			case let .rolaDappVerificationMetadata(definitionAddress):
				"\(filesystemFolderPath)/RolaDappVerificationMetadata-\(definitionAddress)"
			case let .rolaWellKnownFileVerification(url):
				"\(filesystemFolderPath)/RolaWellKnownFileVerification-\(url)"
			case let .tokenPrices(currency):
				"\(filesystemFolderPath)/prices-\(currency.rawValue)"
			case let .dateOfFirstTransaction(address):
				"\(filesystemFolderPath)/account-\(address.address)"
			}
		}

		var filesystemFolderPath: String {
			switch self {
			case let .onLedgerEntity(entity):
				entity.filesystemFolderPath
			case .networkName:
				"NetworkName"
			case .dAppRequestMetadata:
				"DappRequestMetadata"
			case .rolaDappVerificationMetadata:
				"RolaDappVerificationMetadata"
			case .rolaWellKnownFileVerification:
				"RolaWellKnownFileVerification"
			case .tokenPrices:
				"TokenPrices"
			case .dateOfFirstTransaction:
				"DateOfFirstTransaction"
			}
		}

		var expirationDateFilePath: String {
			"\(filesystemFilePath)-expirationDate"
		}

		var lifetime: TimeInterval {
			switch self {
			case .networkName, .onLedgerEntity:
				60 * 60 * 24 // One day cache
			case .dAppRequestMetadata, .rolaDappVerificationMetadata, .rolaWellKnownFileVerification:
				60
			case .tokenPrices:
				60 * 5 // 5 minutes
			case .dateOfFirstTransaction:
				99 * 365 * 60 * 60 * 24
			}
		}
	}

	public enum Error: Swift.Error {
		case dataLoadingFailed
		case expirationDateLoadingFailed
		case entryLifetimeExpired
	}
}
