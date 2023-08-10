import EngineToolkit
import Prelude

extension ManifestBuilder {
	public func withdrawAmount(
		from entity: Address,
		resource: ResourceAddress,
		amount: BigDecimal
	) throws -> ManifestBuilder {
		try callMethod(
			address: entity.intoManifestBuilderAddress(),
			methodName: "withdraw",
			args: [.addressValue(value: resource.intoManifestBuilderAddress()), .decimalValue(value: amount.intoEngine())]
		)
	}

	public func withdrawTokens(
		from entity: Address,
		resource: ResourceAddress,
		tokens: [NonFungibleLocalId]
	) throws -> ManifestBuilder {
		try callMethod(
			address: entity.intoManifestBuilderAddress(),
			methodName: "withdraw",
			args: [
				.addressValue(value: resource.intoManifestBuilderAddress()),
				.arrayValue(
					elementValueKind: .nonFungibleLocalIdValue,
					elements: tokens.map { .nonFungibleLocalIdValue(value: $0) }
				),
			]
		)
	}

	public func setOwnerKeys(
		from entity: Address,
		ownerKeyHashes: [PublicKeyHash]
	) throws -> ManifestBuilder {
		try setMetadata(
			address: entity.intoEngine(),
			key: "owner_keys",
			value: .publicKeyHashArrayValue(value: ownerKeyHashes)
		)
	}

	public func setAccountType(
		from entity: Address,
		type: String
	) throws -> ManifestBuilder {
		try setMetadata(address: entity.intoEngine(), key: "account_type", value: .stringValue(value: type))
	}
}

extension SpecificAddress {
	public func intoManifestBuilderAddress() throws -> ManifestBuilderAddress {
		try .static(value: self.intoEngine())
	}
}

extension BigDecimal {
	public func intoEngine() throws -> EngineKit.Decimal {
		try .init(value: toString())
	}
}
