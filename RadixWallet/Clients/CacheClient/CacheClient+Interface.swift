import Sargon

// MARK: - CacheClient
struct CacheClient: Sendable {
	var save: Save
	var load: Load
	var removeFile: RemoveFile
	var removeFolder: RemoveFolder
	var removeAll: RemoveAll

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
	typealias Save = @Sendable (Encodable, Entry) -> Void
	typealias Load = @Sendable (Decodable.Type, Entry) throws -> Decodable
	typealias RemoveFile = @Sendable (Entry) -> Void
	typealias RemoveFolder = @Sendable (Entry) -> Void
	typealias RemoveAll = @Sendable () -> Void
}

extension DependencyValues {
	var cacheClient: CacheClient {
		get { self[CacheClient.self] }
		set { self[CacheClient.self] = newValue }
	}
}

// MARK: - InvalidateCachedDecision
enum InvalidateCachedDecision {
	case cachedIsInvalid
	case cachedIsValid
}

extension CacheClient {
	func withCaching<Model: Codable>(
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

extension Address {
	fileprivate func filesystemFolderPath(rootName folderRoot: String) -> String {
		switch self {
		case let .account(accountAddress):
			"\(folderRoot)/accounts/\(accountAddress.address)"
		case .resource:
			"\(folderRoot)/resources"
		case .pool:
			"\(folderRoot)/resourcePools"
		case .validator:
			"\(folderRoot)/validators"
		case .component:
			"\(folderRoot)/componentAddress"
		default:
			"\(folderRoot)/generic"
		}
	}

	fileprivate func filesystemFilePath(folderPath filesystemFolderPath: String) -> String {
		switch self {
		case .account:
			"\(filesystemFolderPath)/details"
		case let .resource(resourceAddress):
			"\(filesystemFolderPath)/\(resourceAddress.address)"
		case let .pool(poolAddress):
			"\(filesystemFolderPath)/\(poolAddress.address)"
		case let .validator(validatorAddress):
			"\(filesystemFolderPath)/\(validatorAddress.address)"
		case let .component(componentAddress):
			"\(filesystemFolderPath)/\(componentAddress.address)"
		default:
			"\(filesystemFolderPath)/\(self.address)"
		}
	}
}

extension CacheClient {
	enum Entry: Equatable {
		static let root: String = "RadixWallet"

		init(address: some AddressProtocol) {
			self = .onLedgerEntity(.init(address: address))
		}

		enum OnLedgerEntity: Hashable {
			case address(Address)

			init(address: some AddressProtocol) {
				self = .address(address.asGeneral)
			}

			case nonFungibleData(NonFungibleGlobalId)
			case nonFungibleIdPage(
				accountAddress: AccountAddress,
				resourceAddress: ResourceAddress,
				pageCursor: String?
			)

			var filesystemFilePath: String {
				switch self {
				case let .address(address):
					return address.filesystemFilePath(folderPath: filesystemFolderPath)
				case let .nonFungibleData(nonFungibleGlobalId):
					return nonFungibleGlobalId.description
				case let .nonFungibleIdPage(_, resourceAddress, pageCursor):
					let file = "nonFungibleIds-" + resourceAddress.address + (pageCursor.map { "-\($0)" } ?? "")
					return file
				}
			}

			var filesystemFolderPath: String {
				let folderRoot = "OnLedgerEntity"
				switch self {
				case let .address(address):
					return address.filesystemFolderPath(rootName: folderRoot)
				case .nonFungibleData:
					return "\(folderRoot)/nonFungiblesData"
				case let .nonFungibleIdPage(accountAddress, _, _):
					return "\(folderRoot)/accounts/\(accountAddress.address)"
				}
			}
		}

		case onLedgerEntity(OnLedgerEntity)
		case networkName(_ url: String)
		case dAppRequestMetadata(_ definitionAddress: String)
		case rolaDappVerificationMetadata(_ definitionAddress: String)
		case rolaWellKnownFileVerification(_ url: String)
		case tokenPrices(_ currency: FiatCurrency)
		case dateOfFirstTransaction(_ accountAddress: AccountAddress)
		case accountLockerClaimDetails(_ accountAddress: AccountAddress, _ lockerAddress: LockerAddress)
		case dAppsDirectory

		var filesystemFilePath: String {
			switch self {
			case let .onLedgerEntity(entity):
				"\(filesystemFolderPath)/\(entity.filesystemFilePath)"
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
			case let .accountLockerClaimDetails(accountAddress, lockerAddress):
				"\(filesystemFolderPath)/\(accountAddress.address)/\(lockerAddress.address)"
			case .dAppsDirectory:
				"\(filesystemFolderPath)/dApps"
			}
		}

		var filesystemFolderPath: String {
			let path = switch self {
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
			case .accountLockerClaimDetails:
				"AccountLockerClaimDetails"
			case .dAppsDirectory:
				"DAppsDirectory"
			}

			return "\(Self.root)/\(path)"
		}

		var expirationDateFilePath: String {
			"\(filesystemFilePath)-expirationDate"
		}

		var lifetime: TimeInterval {
			switch self {
			case .networkName, .onLedgerEntity, .dAppsDirectory:
				60 * 60 * 24 // One day cache
			case .dAppRequestMetadata, .rolaDappVerificationMetadata, .rolaWellKnownFileVerification:
				60
			case .tokenPrices:
				60 * 5 // 5 minutes
			case .dateOfFirstTransaction, .accountLockerClaimDetails:
				99 * 365 * 60 * 60 * 24
			}
		}
	}

	enum Error: Swift.Error {
		case dataLoadingFailed
		case expirationDateLoadingFailed
		case entryLifetimeExpired
	}
}
