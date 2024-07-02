
extension OnLedgerEntity.Metadata {
	public init(_ raw: GatewayAPI.EntityMetadataCollection?) {
		self.init(
			name: raw?.name,
			symbol: raw?.symbol,
			description: raw?.description,
			iconURL: raw?.iconURL,
			infoURL: raw?.infoURL,
			tags: raw?.extractTags() ?? [],
			dappDefinitions: raw?.dappDefinitions?.compactMap { try? DappDefinitionAddress(validatingAddress: $0) },
			dappDefinition: raw?.dappDefinition.flatMap { try? DappDefinitionAddress(validatingAddress: $0) },
			validator: raw?.validator,
			poolUnit: raw?.pool,
			poolUnitResource: raw?.poolUnitResource,
			claimedEntities: raw?.claimedEntities,
			claimedWebsites: raw?.claimedWebsites,
			accountType: raw?.accountType,
			ownerKeys: raw?.ownerKeys,
			ownerBadge: raw?.ownerBadge,
			arbitraryItems: raw?.arbitraryItems ?? [],
			isComplete: raw?.isComplete ?? false
		)
	}
}

extension OnLedgerEntity.Metadata {
	public enum MetadataError: Error, CustomStringConvertible {
		case missingName
		case missingDappDefinition
		case accountTypeNotDappDefinition
		case missingClaimedEntities
		case entityNotClaimed
		case missingClaimedWebsites
		case websiteNotClaimed
		case dAppDefinitionNotReciprocating

		public var description: String {
			switch self {
			case .missingName:
				"The entity has no name"
			case .missingDappDefinition:
				"The entity has no dApp definition address"
			case .accountTypeNotDappDefinition:
				"The account is not of the type `dapp definition`"
			case .missingClaimedEntities:
				"The dapp definition has no claimed_entities key"
			case .entityNotClaimed:
				"The entity is not claimed by the dApp definition"
			case .missingClaimedWebsites:
				"The dapp definition has no claimed_websites key"
			case .websiteNotClaimed:
				"The website is not claimed by the dApp definition"
			case .dAppDefinitionNotReciprocating:
				"This dApp definition does not point back to the dApp definition that claims to be associated with it"
			}
		}
	}

	/// Check that `account_type` is present and equal to `dapp_definition`
	public func validateAccountType() throws {
		guard accountType == .dappDefinition else {
			throw MetadataError.accountTypeNotDappDefinition
		}
	}

	/// Check that `claimed_entities` is present and contains the provided `Address`
	public func validate(dAppEntity entity: Address) throws {
		guard let claimedEntities else {
			throw MetadataError.missingClaimedEntities
		}

		guard claimedEntities.contains(entity.address) else {
			throw MetadataError.entityNotClaimed
		}
	}

	/// Check that `claimed_websites`is present and contains the provided website `URL`
	public func validate(website: URL) throws {
		guard let claimedWebsites else {
			throw MetadataError.missingClaimedWebsites
		}

		guard claimedWebsites.contains(website) else {
			throw MetadataError.websiteNotClaimed
		}
	}

	/// Validate that `dapp_definitions` is present and contains the provided `dAppDefinitionAddress`
	public func validate(dAppDefinitionAddress: DappDefinitionAddress) throws {
		guard let dappDefinitions, dappDefinitions.contains(dAppDefinitionAddress) else {
			throw MetadataError.dAppDefinitionNotReciprocating
		}
	}
}

extension GatewayAPI.EntityMetadataItemValue {
	public var asString: String? {
		typed.stringValue?.value
	}

	public var asStringCollection: [String]? {
		typed.stringArrayValue?.values
	}

	public var asURL: URL? {
		(typed.urlValue?.value).flatMap(URL.init)
	}

	public var asURLCollection: [URL]? {
		typed.urlArrayValue?.values.compactMap(URL.init)
	}

	public var asOriginCollection: [URL]? {
		typed.originArrayValue?.values.compactMap(URL.init)
	}

	public var asGlobalAddress: String? {
		typed.globalAddressValue?.value
	}

	public var asNonFungibleLocalID: NonFungibleLocalId? {
		guard let raw = typed.nonFungibleLocalIdValue?.value else {
			return nil
		}
		do {
			return try NonFungibleLocalId(raw)
		} catch {
			loggerGlobal.error("Failed to convert NonFungibleLocalId from string: \(raw), error: \(error) => FILTERED OUT.")
			return nil
		}
	}

	public var asGlobalAddressCollection: [String]? {
		typed.globalAddressArrayValue?.values
	}

	public var publicKeyHashes: [OnLedgerEntity.Metadata.PublicKeyHash]? {
		typed.publicKeyHashArrayValue?.values.map { OnLedgerEntity.Metadata.PublicKeyHash(raw: $0) }
	}
}

extension OnLedgerEntity.Metadata.PublicKeyHash {
	init(raw: GatewayAPI.PublicKeyHash) {
		switch raw {
		case let .ecdsaSecp256k1(publicKeyHashEcdsaSecp256k1):
			self = .ecdsaSecp256k1(publicKeyHashEcdsaSecp256k1.hashHex)
		case let .eddsaEd25519(publicKeyHashEddsaEd25519):
			self = .eddsaEd25519(publicKeyHashEddsaEd25519.hashHex)
		}
	}
}

extension GatewayAPI.EntityMetadataCollection {
	public func value(_ key: EntityMetadataKey) -> GatewayAPI.EntityMetadataItemValue? {
		items[key]?.value
	}

	public var name: String? {
		value(.name)?.asString
	}

	public var symbol: String? {
		value(.symbol)?.asString
	}

	public var description: String? {
		value(.description)?.asString
	}

	public var tags: [String]? {
		value(.tags)?.asStringCollection
	}

	public var iconURL: URL? {
		value(.iconURL)?.asURL
	}

	public var infoURL: URL? {
		value(.infoURL)?.asURL
	}

	public var dappDefinition: String? {
		value(.dappDefinition)?.asGlobalAddress
	}

	public var dappDefinitions: [String]? {
		value(.dappDefinitions)?.asGlobalAddressCollection
	}

	public var claimedEntities: [String]? {
		value(.claimedEntities)?.asGlobalAddressCollection
	}

	public var claimedWebsites: [URL]? {
		value(.claimedWebsites)?.asOriginCollection
	}

	public var accountType: OnLedgerEntity.AccountType? {
		value(.accountType)?.asString.flatMap(OnLedgerEntity.AccountType.init)
	}

	public var ownerKeys: OnLedgerEntity.Metadata.PublicKeyHashesWithStateVersion? {
		items[.ownerKeys]?.map(\.publicKeyHashes)
	}

	public var ownerBadge: OnLedgerEntity.Metadata.OwnerBadgeWithStateVersion? {
		items[.ownerBadge]?.map(\.asNonFungibleLocalID)
	}

	public var arbitraryItems: [OnLedgerEntity.Metadata.ArbitraryItem] {
		let standardKeys = EntityMetadataKey.allCases.map(\.rawValue)
		return items.filter { !standardKeys.contains($0.key) }
	}

	public var validator: ValidatorAddress? {
		extract(
			key: .validator,
			from: \.asGlobalAddress,
			transform: ValidatorAddress.init(validatingAddress:)
		)
	}

	public var pool: PoolAddress? {
		extract(
			key: .pool,
			from: \.asGlobalAddress,
			transform: PoolAddress.init(validatingAddress:)
		)
	}

	public var poolUnitResource: ResourceAddress? {
		extract(
			key: .poolUnit,
			from: \.asGlobalAddress,
			transform: ResourceAddress.init(validatingAddress:)
		)
	}

	private func extract<Value, Field>(
		key: EntityMetadataKey,
		from keyPath: KeyPath<GatewayAPI.EntityMetadataItemValue, Field?>,
		transform: @escaping (Field) throws -> Value
	) -> Value? where Value: Hashable & Codable {
		extractWithAtStateVersion(key: key, from: keyPath, transform: transform)?.value
	}

	private func extractWithAtStateVersion<Value, Field>(
		key: EntityMetadataKey,
		from keyPath: KeyPath<GatewayAPI.EntityMetadataItemValue, Field?>,
		transform: @escaping (Field) throws -> Value
	) -> OnLedgerEntity.Metadata.ValueAtStateVersion<Value>? {
		guard let itemAtStateVersion = items[key] else {
			return nil
		}

		do {
			return try itemAtStateVersion.map {
				guard let field = $0[keyPath: keyPath] else {
					assertionFailure("item found, but it was not wrapped in the expected field")
					return nil
				}
				return try transform(field)
			}
		} catch {
			loggerGlobal.error("Failed to extract metadata \(error.localizedDescription)")
			return nil
		}
	}

	var isComplete: Bool {
		nextCursor == nil
	}
}

public typealias AtStateVersion = Int64
extension [GatewayAPI.EntityMetadataItem] {
	public typealias Key = EntityMetadataKey

	public subscript(key: Key) -> OnLedgerEntity.Metadata.ValueAtStateVersion<GatewayAPI.EntityMetadataItemValue>? {
		guard let item = first(where: { $0.key == key.rawValue }) else {
			return nil
		}
		return OnLedgerEntity.Metadata.ValueAtStateVersion(value: item.value, lastUpdatedAtStateVersion: item.lastUpdatedAtStateVersion)
	}

	public subscript(customKey key: String) -> OnLedgerEntity.Metadata.ValueAtStateVersion<GatewayAPI.EntityMetadataItemValue>? {
		guard let item = first(where: { $0.key == key }) else {
			return nil
		}
		return OnLedgerEntity.Metadata.ValueAtStateVersion(value: item.value, lastUpdatedAtStateVersion: item.lastUpdatedAtStateVersion)
	}
}

extension GatewayAPI.EntityMetadataCollection {
	@Sendable public func extractTags() -> [AssetTag] {
		tags?.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.init) ?? []
	}
}
