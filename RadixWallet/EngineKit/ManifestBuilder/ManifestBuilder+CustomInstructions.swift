import EngineToolkitimport EngineToolkit
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

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		try .init(
			instructions: instructions().withInstructionAdded(instruction, at: index),
			blobs: blobs()
		)
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: RETDecimal = .temporaryStandardFee
	) throws -> TransactionManifest {
		try withInstructionAdded(
			.lockFeeCall(address: address, fee: fee),
			at: 0
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

extension Instruction {
	static func lockFeeCall(
		address: Address,
		fee: RETDecimal
	) throws -> Instruction {
		try .callMethod(
			address: .static(value: .init(address: address.address)),
			methodName: "lock_fee",
			args: .tupleValue(
				fields: [
					.decimalValue(value: fee),
				]
			)
		)
	}
}
