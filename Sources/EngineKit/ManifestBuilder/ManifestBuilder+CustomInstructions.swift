import EngineToolkit
import Prelude

extension ManifestBuilder {
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

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		.init(name: UUID().uuidString)
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
