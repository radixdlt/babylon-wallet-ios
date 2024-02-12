

extension ManifestBuilder {
	public func setOwnerKeys(
		from entity: Address,
		ownerKeyHashes: [RETPublicKeyHash]
	) throws -> ManifestBuilder {
		try metadataSet(
			address: entity.intoEngine(),
			key: "owner_keys",
			value: .publicKeyHashArrayValue(value: ownerKeyHashes)
		)
	}

	public func setAccountType(
		from entity: Address,
		type: String
	) throws -> ManifestBuilder {
		try metadataSet(address: entity.intoEngine(), key: "account_type", value: .stringValue(value: type))
	}

	public func metadataSet(
		address: RETAddress,
		key: String,
		value: MetadataValue
	) throws -> ManifestBuilder {
		panic()
	}
}

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		panic()
	}
}

extension SpecificAddress {
	public func intoManifestBuilderAddress() throws -> ManifestBuilderAddress {
		try .static(value: self.intoEngine())
	}
}

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		try .init(
			instructions: instructions().withInstructionAdded(instruction, at: index),
			blobs: blobs()
		)
	}
}

extension Instructions {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> Instructions {
		var instructionList = self.instructionsList()
		instructionList.insert(instruction, at: index)
		return try .fromInstructions(instructions: instructionList, networkId: self.networkId())
	}
}
