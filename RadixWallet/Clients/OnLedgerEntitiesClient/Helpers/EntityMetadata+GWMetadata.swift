
extension OnLedgerEntity.Metadata {
	public init(_ raw: GatewayAPI.EntityMetadataCollection?) {
		self.init(
			name: raw?.name,
			symbol: raw?.symbol,
			description: raw?.description,
			iconURL: raw?.iconURL,
			tags: raw?.extractTags() ?? [],
			dappDefinitions: raw?.dappDefinitions?.compactMap { try? DappDefinitionAddress(validatingAddress: $0) },
			dappDefinition: raw?.dappDefinition.flatMap { try? DappDefinitionAddress(validatingAddress: $0) },
			validator: raw?.validator,
			poolUnit: raw?.pool,
			poolUnitResource: raw?.poolUnitResource,
			claimedEntities: raw?.claimedEntities,
			claimedWebsites: raw?.claimedWebsites,
			accountType: raw?.accountType,
			ownerKeys: raw?.ownerKeys
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

	/// Check that `claimed_entities` is present and contains the provided `ComponentAddress`
	public func validate(dAppComponent component: ComponentAddress) throws {
		guard let claimedEntities else {
			throw MetadataError.missingClaimedEntities
		}

		guard claimedEntities.contains(component.address) else {
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

	public var asGlobalAddressCollection: [String]? {
		typed.globalAddressArrayValue?.values
	}

	public var publicKeyHashes: [OnLedgerEntity.Metadata.PublicKeyHash]? {
		typed.publicKeyHashArrayValue?.values.map { .init(raw: $0) }
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
	public var name: String? {
		items[.name]?.asString
	}

	public var symbol: String? {
		items[.symbol]?.asString
	}

	public var description: String? {
		items[.description]?.asString
	}

	public var tags: [String]? {
		items[.tags]?.asStringCollection
	}

	public var iconURL: URL? {
		items[.iconURL]?.asURL
	}

	public var dappDefinition: String? {
		items[.dappDefinition]?.asGlobalAddress
	}

	public var dappDefinitions: [String]? {
		items[.dappDefinitions]?.asGlobalAddressCollection
	}

	public var claimedEntities: [String]? {
		items[.claimedEntities]?.asGlobalAddressCollection
	}

	public var claimedWebsites: [URL]? {
		items[.claimedWebsites]?.asOriginCollection
	}

	public var accountType: OnLedgerEntity.AccountType? {
		items[.accountType]?.asString.flatMap(OnLedgerEntity.AccountType.init)
	}

	public var ownerKeys: [OnLedgerEntity.Metadata.PublicKeyHash]? {
		items[.ownerKeys]?.publicKeyHashes
	}

	public var validator: ValidatorAddress? {
		extract(
			key: .validator,
			from: \.asGlobalAddress,
			transform: ValidatorAddress.init(validatingAddress:)
		)
	}

	public var pool: ResourcePoolAddress? {
		extract(
			key: .pool,
			from: \.asGlobalAddress,
			transform: ResourcePoolAddress.init(validatingAddress:)
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
	) -> Value? {
		guard let item = items[key] else {
			return nil
		}

		guard let field = item[keyPath: keyPath] else {
			assertionFailure("item found, but it was not wrapped in the expected field")
			return nil
		}

		do {
			return try transform(field)
		} catch {
			assertionFailure(error.localizedDescription)
			return nil
		}
	}
}

extension [GatewayAPI.EntityMetadataItem] {
	public typealias Key = EntityMetadataKey

	public subscript(key: Key) -> GatewayAPI.EntityMetadataItemValue? {
		first { $0.key == key.rawValue }?.value
	}

	public subscript(customKey key: String) -> GatewayAPI.EntityMetadataItemValue? {
		first { $0.key == key }?.value
	}
}

extension GatewayAPI.EntityMetadataCollection {
	@Sendable public func extractTags() -> [AssetTag] {
		tags?.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.init) ?? []
	}
}
