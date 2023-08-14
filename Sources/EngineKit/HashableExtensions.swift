import EngineToolkit
import Foundation

// MARK: - NonFungibleGlobalId + Hashable
/// Conformance of RET models to Hashable. An improvement would be if RET could add the below two new APIs:
/// - `equals(other:_)-> Bool`
/// - `hashed() -> [UInt8]` // speculative.
/// That would allow to use a tool like Sourcery to autogenerate Equatable and Hashable conformances.

extension NonFungibleGlobalId: Hashable {
	public static func == (lhs: EngineToolkit.NonFungibleGlobalId, rhs: EngineToolkit.NonFungibleGlobalId) -> Bool {
		lhs.asStr() == rhs.asStr()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(asStr())
	}
}

// MARK: - TransactionManifest + Hashable
extension TransactionManifest: Hashable {
	public static func == (lhs: EngineToolkit.TransactionManifest, rhs: EngineToolkit.TransactionManifest) -> Bool {
		lhs.blobs() == rhs.blobs() &&
			lhs.instructions() == rhs.instructions()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(blobs())
		hasher.combine(instructions())
	}
}

// MARK: - Instructions + Hashable
extension Instructions: Hashable {
	public static func == (lhs: EngineToolkit.Instructions, rhs: EngineToolkit.Instructions) -> Bool {
		lhs.instructionsList() == rhs.instructionsList() &&
			lhs.networkId() == rhs.networkId()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(instructionsList())
		hasher.combine(networkId())
	}
}

// MARK: - Instruction + Hashable
extension Instruction: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .takeAllFromWorktop(resourceAddress):
			hasher.combine("takeAllFromWorktop")
			hasher.combine(resourceAddress)
		case let .takeFromWorktop(resourceAddress, amount):
			hasher.combine("takeFromWorktop")
			hasher.combine(resourceAddress)
			hasher.combine(amount)
		case let .takeNonFungiblesFromWorktop(resourceAddress, ids):
			hasher.combine("takeNonFungiblesFromWorktop")
			hasher.combine(resourceAddress)
			hasher.combine(ids)
		case let .returnToWorktop(bucketId):
			hasher.combine("returnToWorktop")
			hasher.combine(bucketId)
		case let .assertWorktopContains(resourceAddress, amount):
			hasher.combine("assertWorktopContains")
			hasher.combine(resourceAddress)
			hasher.combine(amount)
		case let .assertWorktopContainsNonFungibles(resourceAddress, ids):
			hasher.combine("assertWorktopContainsNonFungibles")
			hasher.combine(resourceAddress)
			hasher.combine(ids)
		case .popFromAuthZone:
			hasher.combine("popFromAuthZone")
		case .clearAuthZone:
			hasher.combine("clearAuthZone")
		case .clearSignatureProofs:
			hasher.combine("clearSignatureProofs")
		case .dropAllProofs:
			hasher.combine("dropAllProofs")
		case let .pushToAuthZone(proofId):
			hasher.combine("pushToAuthZone")
			hasher.combine(proofId)
		case let .createProofFromAuthZoneOfAmount(resourceAddress, amount):
			hasher.combine("createProofFromAuthZoneOfAmount")
			hasher.combine(resourceAddress)
			hasher.combine(amount)
		case let .createProofFromAuthZoneOfNonFungibles(resourceAddress, ids):
			hasher.combine("createProofFromAuthZoneOfNonFungibles")
			hasher.combine(resourceAddress)
			hasher.combine(ids)
		case let .createProofFromAuthZoneOfAll(resourceAddress):
			hasher.combine("createProofFromAuthZoneOfAll")
			hasher.combine(resourceAddress)
		case let .createProofFromBucketOfAmount(bucketId, amount):
			hasher.combine("createProofFromBucketOfAmount")
			hasher.combine(bucketId)
			hasher.combine(amount)
		case let .createProofFromBucketOfNonFungibles(bucketId, ids):
			hasher.combine("createProofFromBucketOfNonFungibles")
			hasher.combine(bucketId)
			hasher.combine(ids)
		case let .createProofFromBucketOfAll(bucketId):
			hasher.combine("createProofFromBucketOfAll")
			hasher.combine(bucketId)
		case let .burnResource(bucketId):
			hasher.combine("burnResource")
			hasher.combine(bucketId)
		case let .cloneProof(proofId):
			hasher.combine("cloneProof")
			hasher.combine(proofId)
		case let .dropProof(proofId):
			hasher.combine("dropProof")
			hasher.combine(proofId)
		case let .callFunction(packageAddress, blueprintName, functionName, args):
			hasher.combine("callFunction")
			hasher.combine(packageAddress)
			hasher.combine(blueprintName)
			hasher.combine(functionName)
			hasher.combine(args)
		case let .callMethod(address, methodName, args):
			hasher.combine("callMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		case let .callRoyaltyMethod(address, methodName, args):
			hasher.combine("callRoyaltyMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		case let .callMetadataMethod(address, methodName, args):
			hasher.combine("callMetadataMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		case let .callAccessRulesMethod(address, methodName, args):
			hasher.combine("callAccessRulesMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		case let .assertWorktopContainsAny(resourceAddress):
			hasher.combine("assertWorktopContainsAny")
			hasher.combine(resourceAddress)
		case let .callDirectVaultMethod(address, methodName, args):
			hasher.combine("callDirectVaultMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		case let .allocateGlobalAddress(packageAddress, blueprintName):
			hasher.combine("allocateGlobalAddress")
			hasher.combine(packageAddress)
			hasher.combine(blueprintName)
		}
	}

	public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
		switch (lhs, rhs) {
		case let (.takeAllFromWorktop(lhs), .takeAllFromWorktop(rhs)):
			return lhs == rhs
		case let (.takeFromWorktop(lhsAddress, lhsAmount), .takeFromWorktop(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount
		case let (.takeNonFungiblesFromWorktop(lhsAddress, lhsIds), .takeNonFungiblesFromWorktop(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds
		case let (.returnToWorktop(lhs), .returnToWorktop(rhs)):
			return lhs == rhs
		case let (.assertWorktopContains(lhsAddress, lhsAmount), .assertWorktopContains(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount
		case let (.assertWorktopContainsNonFungibles(lhsAddress, lhsIds), .assertWorktopContainsNonFungibles(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds
		case (.popFromAuthZone, .popFromAuthZone),
		     (.clearAuthZone, .clearAuthZone),
		     (.clearSignatureProofs, .clearSignatureProofs),
		     (.dropAllProofs, .dropAllProofs):
			return true
		case let (.pushToAuthZone(lhs), .pushToAuthZone(rhs)):
			return lhs == rhs
		case let (.createProofFromAuthZoneOfAmount(lhsAddress, lhsAmount), .createProofFromAuthZoneOfAmount(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount
		case let (.createProofFromAuthZoneOfNonFungibles(lhsAddress, lhsIds), .createProofFromAuthZoneOfNonFungibles(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds
		case let (.createProofFromAuthZoneOfAll(lhs), .createProofFromAuthZoneOfAll(rhs)):
			return lhs == rhs
		case let (.burnResource(lhs), .burnResource(rhs)):
			return lhs == rhs
		case let (.cloneProof(lhs), .cloneProof(rhs)):
			return lhs == rhs
		case let (.dropProof(lhs), .dropProof(rhs)):
			return lhs == rhs
		case let (.createProofFromBucketOfAmount(lhsBucketId, lhsAmount), .createProofFromBucketOfAmount(rhsBucketId, rhsAmount)):
			return lhsBucketId == rhsBucketId && lhsAmount == rhsAmount
		case let (.createProofFromBucketOfNonFungibles(lhsBucketId, lhsIds), .createProofFromBucketOfNonFungibles(rhsBucketId, rhsIds)):
			return lhsBucketId == rhsBucketId && lhsIds == rhsIds
		case let (.createProofFromBucketOfAll(lhs), .createProofFromBucketOfAll(rhs)):
			return lhs == rhs
		case let (.callFunction(lhsPackageAddress, lhsBlueprintName, lhsFunctionName, lhsArgs), .callFunction(rhsPackageAddress, rhsBlueprintName, rhsFunctionName, rhsArgs)):
			return lhsPackageAddress == rhsPackageAddress && lhsBlueprintName == rhsBlueprintName && lhsFunctionName == rhsFunctionName && lhsArgs == rhsArgs
		case let (.callMethod(lhsAddress, lhsMethodName, lhsArgs), .callMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callRoyaltyMethod(lhsAddress, lhsMethodName, lhsArgs), .callRoyaltyMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callMetadataMethod(lhsAddress, lhsMethodName, lhsArgs), .callMetadataMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callAccessRulesMethod(lhsAddress, lhsMethodName, lhsArgs), .callAccessRulesMethod(rhsAddress, rhsMethodName, rhsArgs)):
			return lhsAddress == rhsAddress && lhsMethodName == rhsMethodName && lhsArgs == rhsArgs
		default:
			return false
		}
	}
}

// MARK: - ManifestValue + Hashable
extension ManifestValue: Hashable {
	public static func == (lhs: ManifestValue, rhs: ManifestValue) -> Bool {
		switch (lhs, rhs) {
		case let (.boolValue(lhs), .boolValue(rhs)):
			return lhs == rhs
		case let (.i8Value(lhs), .i8Value(rhs)):
			return lhs == rhs
		case let (.i16Value(lhs), .i16Value(rhs)):
			return lhs == rhs
		case let (.i32Value(lhs), .i32Value(rhs)):
			return lhs == rhs
		case let (.i64Value(lhs), .i64Value(rhs)):
			return lhs == rhs
		case let (.i128Value(lhs), .i128Value(rhs)):
			return lhs == rhs
		case let (.u8Value(lhs), .u8Value(rhs)):
			return lhs == rhs
		case let (.u16Value(lhs), .u16Value(rhs)):
			return lhs == rhs
		case let (.u32Value(lhs), .u32Value(rhs)):
			return lhs == rhs
		case let (.u64Value(lhs), .u64Value(rhs)):
			return lhs == rhs
		case let (.u128Value(lhs), .u128Value(rhs)):
			return lhs == rhs
		case let (.stringValue(lhs), .stringValue(rhs)):
			return lhs == rhs
		case let (.enumValue(lhsDiscriminator, lhsFields), .enumValue(rhsDiscriminator, rhsFields)):
			return lhsDiscriminator == rhsDiscriminator && lhsFields == rhsFields
		case let (.arrayValue(lhsElementValueKind, lhsElements), .arrayValue(rhsElementValueKind, rhsElements)):
			return lhsElementValueKind == rhsElementValueKind && lhsElements == rhsElements
		case let (.tupleValue(lhs), .tupleValue(rhs)):
			return lhs == rhs
		case let (.mapValue(lhsKeyValueKind, lhsValueValueKind, lhsEntries), .mapValue(rhsKeyValueKind, rhsValueValueKind, rhsEntries)):
			return lhsKeyValueKind == rhsKeyValueKind && lhsValueValueKind == rhsValueValueKind && lhsEntries == rhsEntries
		case let (.addressValue(lhs), .addressValue(rhs)):
			return lhs == rhs
		case let (.bucketValue(lhs), .bucketValue(rhs)):
			return lhs == rhs
		case let (.proofValue(lhs), .proofValue(rhs)):
			return lhs == rhs
		case let (.expressionValue(lhs), .expressionValue(rhs)):
			return lhs == rhs
		case let (.blobValue(lhs), .blobValue(rhs)):
			return lhs == rhs
		case let (.decimalValue(lhs), .decimalValue(rhs)):
			return lhs == rhs
		case let (.preciseDecimalValue(lhs), .preciseDecimalValue(rhs)):
			return lhs == rhs
		case let (.nonFungibleLocalIdValue(lhs), .nonFungibleLocalIdValue(rhs)):
			return lhs == rhs
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .boolValue(value):
			hasher.combine("boolValue")
			hasher.combine(value)
		case let .i8Value(value):
			hasher.combine("i8Value")
			hasher.combine(value)
		case let .i16Value(value):
			hasher.combine("i16Value")
			hasher.combine(value)
		case let .i32Value(value):
			hasher.combine("i32Value")
			hasher.combine(value)
		case let .i64Value(value):
			hasher.combine("i64Value")
			hasher.combine(value)
		case let .i128Value(value):
			hasher.combine("i128Value")
			hasher.combine(value)
		case let .u8Value(value):
			hasher.combine("u8Value")
			hasher.combine(value)
		case let .u16Value(value):
			hasher.combine("u16Value")
			hasher.combine(value)
		case let .u32Value(value):
			hasher.combine("u32Value")
			hasher.combine(value)
		case let .u64Value(value):
			hasher.combine("u64Value")
			hasher.combine(value)
		case let .u128Value(value):
			hasher.combine("u128Value")
			hasher.combine(value)
		case let .stringValue(value):
			hasher.combine("stringValue")
			hasher.combine(value)
		case let .enumValue(discriminator, fields):
			hasher.combine("enumValue")
			hasher.combine(discriminator)
			hasher.combine(fields)
		case let .arrayValue(elementValueKind, elements):
			hasher.combine("arrayValue")
			hasher.combine(elementValueKind)
			hasher.combine(elements)
		case let .tupleValue(fields):
			hasher.combine("tupleValue")
			hasher.combine(fields)
		case let .mapValue(keyValueKind, valueValueKind, entries):
			hasher.combine("mapValue")
			hasher.combine(keyValueKind)
			hasher.combine(valueValueKind)
			hasher.combine(entries)
		case let .addressValue(value):
			hasher.combine("addressValue")
			hasher.combine(value)
		case let .bucketValue(value):
			hasher.combine("bucketValue")
			hasher.combine(value)
		case let .proofValue(value):
			hasher.combine("proofValue")
			hasher.combine(value)
		case let .expressionValue(value):
			hasher.combine("expressionValue")
			hasher.combine(value)
		case let .blobValue(value):
			hasher.combine("blobValue")
			hasher.combine(value)
		case let .decimalValue(value):
			hasher.combine("decimalValue")
			hasher.combine(value)
		case let .preciseDecimalValue(value):
			hasher.combine("preciseDecimalValue")
			hasher.combine(value)
		case let .nonFungibleLocalIdValue(value):
			hasher.combine("nonFungibleLocalIdValue")
			hasher.combine(value)
		case let .addressReservationValue(value):
			hasher.combine("addressReservationValue")
			hasher.combine(value)
		}
	}
}

// MARK: - MapEntry + Hashable
extension MapEntry: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(key)
		hasher.combine(value)
	}

	public static func == (lhs: MapEntry, rhs: MapEntry) -> Bool {
		lhs.key == lhs.key &&
			lhs.value == lhs.value
	}
}

// MARK: - EngineToolkit.Decimal + Hashable
extension EngineToolkit.Decimal: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.asStr())
	}

	public static func == (lhs: EngineToolkit.Decimal, rhs: EngineToolkit.Decimal) -> Bool {
		lhs.equal(other: rhs)
	}
}

// MARK: - EngineToolkit.PreciseDecimal + Hashable
extension EngineToolkit.PreciseDecimal: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.asStr())
	}

	public static func == (lhs: EngineToolkit.PreciseDecimal, rhs: EngineToolkit.PreciseDecimal) -> Bool {
		lhs.equal(other: rhs)
	}
}

// MARK: - ManifestBlobRef + Hashable
extension ManifestBlobRef: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.value.bytes())
	}

	public static func == (lhs: ManifestBlobRef, rhs: ManifestBlobRef) -> Bool {
		lhs.value == rhs.value
	}
}

// MARK: - Hash + Equatable
extension Hash: Equatable {
	public static func == (lhs: EngineToolkit.Hash, rhs: EngineToolkit.Hash) -> Bool {
		lhs.bytes() == rhs.bytes()
	}
}

// MARK: - EngineToolkit.Address + Hashable
extension EngineToolkit.Address: Hashable {
	public static func == (lhs: EngineToolkit.Address, rhs: EngineToolkit.Address) -> Bool {
		lhs.addressString() == rhs.addressString()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(addressString())
	}
}

// MARK: - TransactionIntent + Hashable
extension TransactionIntent: Hashable {
	public static func == (lhs: EngineToolkit.Intent, rhs: EngineToolkit.Intent) -> Bool {
		lhs.header() == rhs.header() &&
			lhs.manifest() == rhs.manifest()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(header())
		hasher.combine(manifest())
	}
}

// MARK: - ExecutionAnalysis + Hashable
extension ExecutionAnalysis: Hashable {
	public static func == (lhs: ExecutionAnalysis, rhs: ExecutionAnalysis) -> Bool {
		lhs.feeLocks == rhs.feeLocks &&
			lhs.feeSummary == rhs.feeSummary &&
			lhs.transactionType == rhs.transactionType
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(feeLocks)
		hasher.combine(feeSummary)
		hasher.combine(transactionType)
	}
}

// MARK: - FeeLocks + Hashable
extension FeeLocks: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.lock)
		hasher.combine(self.contingentLock)
	}

	public static func == (lhs: FeeLocks, rhs: FeeLocks) -> Bool {
		lhs.lock == rhs.lock && lhs.contingentLock == rhs.contingentLock
	}
}

// MARK: - FeeSummary + Hashable
extension FeeSummary: Hashable {
	public static func == (lhs: FeeSummary, rhs: FeeSummary) -> Bool {
		lhs.networkFee == rhs.networkFee &&
			lhs.royaltyFee == rhs.royaltyFee
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.networkFee)
		hasher.combine(self.royaltyFee)
	}
}

// MARK: - TransactionType + Hashable
extension TransactionType: Hashable {
	public static func == (lhs: TransactionType, rhs: TransactionType) -> Bool {
		switch (lhs, rhs) {
		case let (
			.simpleTransfer(lhsFromAddress, lhsToAddress, lhsTransferred),
			.simpleTransfer(rhsFromAddress, rhsToAddress, rhsTransferred)
		):
			return lhsFromAddress == rhsFromAddress && lhsToAddress == rhsToAddress && lhsTransferred == rhsTransferred
		case let (
			.transfer(lhsFromAddress, lhsTransfers),
			.transfer(rhsFromAddress, rhsTransfers)
		):
			return lhsFromAddress == rhsFromAddress && lhsTransfers == rhsTransfers
		case let (
			.generalTransaction(
				lhsAccountProofs,
				lhsAccountWithdraws,
				lhsAccountDeposits,
				lhsAddressesInManifest,
				lhsMetadataOfNewlyCreatedEntities,
				lhsDataOfNewlyMintedNonFungibles,
				lhsAddressesOfNewlyCreatedEntities
			),
			.generalTransaction(
				rhsAccountProofs,
				rhsAccountWithdraws,
				rhsAccountDeposits,
				rhsAddressesInManifest,
				rhsMetadataOfNewlyCreatedEntities,
				rhsDataOfNewlyMintedNonFungibles,
				rhsAddressesOfNewlyCreatedEntities
			)
		):
			return lhsAccountProofs == rhsAccountProofs &&
				lhsAccountWithdraws == rhsAccountWithdraws &&
				lhsAccountDeposits == rhsAccountDeposits &&
				lhsAddressesInManifest == rhsAddressesInManifest &&
				lhsMetadataOfNewlyCreatedEntities == rhsMetadataOfNewlyCreatedEntities &&
				lhsDataOfNewlyMintedNonFungibles == rhsDataOfNewlyMintedNonFungibles &&
				lhsAddressesOfNewlyCreatedEntities == rhsAddressesOfNewlyCreatedEntities
		case (.nonConforming, .nonConforming):
			return true
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .simpleTransfer(from, to, transferred):
			hasher.combine("simpleTransfer")
			hasher.combine(from)
			hasher.combine(to)
			hasher.combine(transferred)
		case let .transfer(from, transfers):
			hasher.combine("transfer")
			hasher.combine(from)
			hasher.combine(transfers)
		case let .generalTransaction(accountProofs, accountWithdraws, accountDeposits, addressesInManifest, metadataOfNewlyCreatedEntities, dataOfNewlyMintedNonFungibles, addressesOfNewlyCreatedEntities):
			hasher.combine("generalTransaction")
			hasher.combine(accountProofs)
			hasher.combine(accountWithdraws)
			hasher.combine(accountDeposits)
			hasher.combine(addressesInManifest)
			hasher.combine(metadataOfNewlyCreatedEntities)
			hasher.combine(dataOfNewlyMintedNonFungibles)
			hasher.combine(addressesOfNewlyCreatedEntities)
		case .nonConforming:
			hasher.combine("nonConforming")
		}
	}
}

// MARK: - ResourceSpecifier + Hashable
extension ResourceSpecifier: Hashable {
	public static func == (lhs: ResourceSpecifier, rhs: ResourceSpecifier) -> Bool {
		switch (lhs, rhs) {
		case let (.amount(lhsResourceAddress, lhsAmount), .amount(rhsResourceAddress, rhsAmount)):
			return lhsResourceAddress == rhsResourceAddress && lhsAmount == rhsAmount
		case let (.ids(lhsResourceAddress, lhsIds), .ids(rhsResourceAddress, rhsIds)):
			return lhsResourceAddress == rhsResourceAddress && lhsIds == rhsIds
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .amount(resourceAddress, amount):
			hasher.combine("amount")
			hasher.combine(resourceAddress)
			hasher.combine(amount)
		case let .ids(resourceAddress, ids):
			hasher.combine("ids")
			hasher.combine(resourceAddress)
			hasher.combine(ids)
		}
	}
}

// MARK: - Resources + Hashable
extension Resources: Hashable {
	public static func == (lhs: Resources, rhs: Resources) -> Bool {
		switch (lhs, rhs) {
		case let (.amount(lhsAmount), .amount(rhsAmount)):
			return lhsAmount == rhsAmount
		case let (.ids(lhsIds), .ids(rhsIds)):
			return lhsIds == rhsIds
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .amount(amount):
			hasher.combine("amount")
			hasher.combine(amount)
		case let .ids(ids):
			hasher.combine("ids")
			hasher.combine(ids)
		}
	}
}

// MARK: - ResourceTracker + Hashable
extension ResourceTracker: Hashable {
	public static func == (lhs: ResourceTracker, rhs: ResourceTracker) -> Bool {
		switch (lhs, rhs) {
		case let (.fungible(lhsAddress, lhsAmount), .fungible(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount
		case let (.nonFungible(lhsAddress, lhsAmount, lhsIds), .nonFungible(rhsAddress, rhsAmount, rhsIds)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount && lhsIds == rhsIds
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .fungible(resourceAddress, amount):
			hasher.combine(resourceAddress)
			hasher.combine(amount)
		case let .nonFungible(resourceAddress, amount, ids):
			hasher.combine(resourceAddress)
			hasher.combine(amount)
			hasher.combine(ids)
		}
	}
}

// MARK: - DecimalSource + Hashable
extension DecimalSource: Hashable {
	public static func == (lhs: DecimalSource, rhs: DecimalSource) -> Bool {
		switch (lhs, rhs) {
		case let (.guaranteed(lhsValue), .guaranteed(rhsValue)):
			return lhsValue == rhsValue
		case let (.predicted(lhsInstructionIndex, lhsValue), .predicted(rhsInstructionIndex, rhsValue)):
			return lhsInstructionIndex == rhsInstructionIndex && lhsValue == rhsValue
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .guaranteed(value):
			hasher.combine(value)
		case let .predicted(instructionIndex, value):
			hasher.combine(instructionIndex)
			hasher.combine(value)
		}
	}
}

// MARK: - MetadataValue + Hashable
extension MetadataValue: Hashable {
	public static func == (lhs: MetadataValue, rhs: MetadataValue) -> Bool {
		switch (lhs, rhs) {
		case let (.stringValue(lhsValue), .stringValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.boolValue(lhsValue), .boolValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.u8Value(lhsValue), .u8Value(rhsValue)):
			return lhsValue == rhsValue
		case let (.u32Value(lhsValue), .u32Value(rhsValue)):
			return lhsValue == rhsValue
		case let (.u64Value(lhsValue), .u64Value(rhsValue)):
			return lhsValue == rhsValue
		case let (.i32Value(lhsValue), .i32Value(rhsValue)):
			return lhsValue == rhsValue
		case let (.i64Value(lhsValue), .i64Value(rhsValue)):
			return lhsValue == rhsValue
		case let (.decimalValue(lhsValue), .decimalValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.globalAddressValue(lhsValue), .globalAddressValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.publicKeyValue(lhsValue), .publicKeyValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.nonFungibleGlobalIdValue(lhsValue), .nonFungibleGlobalIdValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.nonFungibleLocalIdValue(lhsValue), .nonFungibleLocalIdValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.instantValue(lhsValue), .instantValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.urlValue(lhsValue), .urlValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.originValue(lhsValue), .originValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.publicKeyHashValue(lhsValue), .publicKeyHashValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.stringArrayValue(lhsValue), .stringArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.boolArrayValue(lhsValue), .boolArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.u8ArrayValue(lhsValue), .u8ArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.u32ArrayValue(lhsValue), .u32ArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.u64ArrayValue(lhsValue), .u64ArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.i32ArrayValue(lhsValue), .i32ArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.i64ArrayValue(lhsValue), .i64ArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.decimalArrayValue(lhsValue), .decimalArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.globalAddressArrayValue(lhsValue), .globalAddressArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.publicKeyArrayValue(lhsValue), .publicKeyArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.nonFungibleGlobalIdArrayValue(lhsValue), .nonFungibleGlobalIdArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.nonFungibleLocalIdArrayValue(lhsValue), .nonFungibleLocalIdArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.instantArrayValue(lhsValue), .instantArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.urlArrayValue(lhsValue), .urlArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.originArrayValue(lhsValue), .originArrayValue(rhsValue)):
			return lhsValue == rhsValue
		case let (.publicKeyHashArrayValue(lhsValue), .publicKeyHashArrayValue(rhsValue)):
			return lhsValue == rhsValue
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .stringValue(value):
			hasher.combine("stringValue")
			hasher.combine(value)
		case let .boolValue(value):
			hasher.combine("boolValue")
			hasher.combine(value)
		case let .u8Value(value):
			hasher.combine("u8Value")
			hasher.combine(value)
		case let .u32Value(value):
			hasher.combine("u32Value")
			hasher.combine(value)
		case let .u64Value(value):
			hasher.combine("u64Value")
			hasher.combine(value)
		case let .i32Value(value):
			hasher.combine("i32Value")
			hasher.combine(value)
		case let .i64Value(value):
			hasher.combine("i64Value")
			hasher.combine(value)
		case let .decimalValue(value):
			hasher.combine("decimalValue")
			hasher.combine(value)
		case let .globalAddressValue(value):
			hasher.combine("globalAddressValue")
			hasher.combine(value)
		case let .publicKeyValue(value):
			hasher.combine("publicKeyValue")
			hasher.combine(value)
		case let .nonFungibleGlobalIdValue(value):
			hasher.combine("nonFungibleGlobalIdValue")
			hasher.combine(value)
		case let .nonFungibleLocalIdValue(value):
			hasher.combine("nonFungibleLocalIdValue")
			hasher.combine(value)
		case let .instantValue(value):
			hasher.combine("instantValue")
			hasher.combine(value)
		case let .urlValue(value):
			hasher.combine("urlValue")
			hasher.combine(value)
		case let .originValue(value):
			hasher.combine("originValue")
			hasher.combine(value)
		case let .publicKeyHashValue(value):
			hasher.combine("publicKeyHashValue")
			hasher.combine(value)
		case let .stringArrayValue(value):
			hasher.combine("stringArrayValue")
			hasher.combine(value)
		case let .boolArrayValue(value):
			hasher.combine("boolArrayValue")
			hasher.combine(value)
		case let .u8ArrayValue(value):
			hasher.combine("u8ArrayValue")
			hasher.combine(value)
		case let .u32ArrayValue(value):
			hasher.combine("u32ArrayValue")
			hasher.combine(value)
		case let .u64ArrayValue(value):
			hasher.combine("u64ArrayValue")
			hasher.combine(value)
		case let .i32ArrayValue(value):
			hasher.combine("i32ArrayValue")
			hasher.combine(value)
		case let .i64ArrayValue(value):
			hasher.combine("i64ArrayValue")
			hasher.combine(value)
		case let .decimalArrayValue(value):
			hasher.combine("decimalArrayValue")
			hasher.combine(value)
		case let .globalAddressArrayValue(value):
			hasher.combine("globalAddressArrayValue")
			hasher.combine(value)
		case let .publicKeyArrayValue(value):
			hasher.combine("publicKeyArrayValue")
			hasher.combine(value)
		case let .nonFungibleGlobalIdArrayValue(value):
			hasher.combine("nonFungibleGlobalIdArrayValue")
			hasher.combine(value)
		case let .nonFungibleLocalIdArrayValue(value):
			hasher.combine("nonFungibleLocalIdArrayValue")
			hasher.combine(value)
		case let .instantArrayValue(value):
			hasher.combine("instantArrayValue")
			hasher.combine(value)
		case let .urlArrayValue(value):
			hasher.combine("urlArrayValue")
			hasher.combine(value)
		case let .originArrayValue(value):
			hasher.combine("originArrayValue")
			hasher.combine(value)
		case let .publicKeyHashArrayValue(value):
			hasher.combine("publicKeyHashArrayValue")
			hasher.combine(value)
		}
	}
}

// MARK: - ManifestAddress + Hashable
extension ManifestAddress: Hashable {
	public static func == (lhs: ManifestAddress, rhs: ManifestAddress) -> Bool {
		switch (lhs, rhs) {
		case let (.named(lhs), .named(rhs)):
			return lhs == rhs
		case let (.static(lhs), .static(rhs)):
			return lhs == rhs
		default:
			return false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .named(value):
			hasher.combine("named")
			hasher.combine(value)
		case let .static(value):
			hasher.combine("static")
			hasher.combine(value)
		}
	}
}

// MARK: - TransactionHash + Hashable
extension TransactionHash: Hashable {
	public static func == (lhs: TransactionHash, rhs: TransactionHash) -> Bool {
		lhs.asStr() == rhs.asStr()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(asStr())
	}
}
