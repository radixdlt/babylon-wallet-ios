import EngineToolkit

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

// MARK: - TransactionManifest + Equatable
extension TransactionManifest: Equatable {
	public static func == (lhs: EngineToolkit.TransactionManifest, rhs: EngineToolkit.TransactionManifest) -> Bool {
		lhs.instructions() == rhs.instructions() &&
			lhs.blobs() == rhs.blobs()
	}
}

// MARK: - TransactionManifest + Hashable
extension TransactionManifest: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(blobs())
		hasher.combine(instructions())
	}
}

// MARK: - Instructions + Equatable
extension Instructions: Equatable {
	public static func == (lhs: EngineToolkit.Instructions, rhs: EngineToolkit.Instructions) -> Bool {
		lhs.networkId() == rhs.networkId() &&
			lhs.instructionsList() == rhs.instructionsList()
	}
}

// MARK: - Instructions + Hashable
extension Instructions: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(instructionsList())
		hasher.combine(networkId())
	}
}

/// A function call like `dummy(.someCase)` will stop compiling if an
/// associated value is later added to `someCase`case of `Instruction`.
private func dummy(_: Instruction) {
	/* noop */
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
			dummy(.popFromAuthZone)
			hasher.combine("popFromAuthZone")

		case .dropAllProofs:
			dummy(.dropAllProofs)
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

		case .dropNamedProofs:
			dummy(.dropNamedProofs)
			hasher.combine("dropNamedProofs")

		case .dropAuthZoneProofs:
			dummy(.dropAuthZoneProofs)
			hasher.combine("dropAuthZoneProofs")

		case .dropAuthZoneRegularProofs:
			dummy(.dropAuthZoneRegularProofs)
			hasher.combine("dropAuthZoneRegularProofs")

		case .dropAuthZoneSignatureProofs:
			dummy(.dropAuthZoneSignatureProofs)
			hasher.combine("dropAuthZoneSignatureProofs")

		case let .callRoleAssignmentMethod(address, methodName, args):
			hasher.combine("callRoleAssignmentMethod")
			hasher.combine(address)
			hasher.combine(methodName)
			hasher.combine(args)
		}
	}
}

// MARK: - Instruction + Equatable
extension Instruction: Equatable {
	public static func == (lhsOuter: Instruction, rhsOuter: Instruction) -> Bool {
		switch (lhsOuter, rhsOuter) {
		case let (.takeAllFromWorktop(lhs), .takeAllFromWorktop(rhs)):
			return lhs == rhs
		case (.takeAllFromWorktop, _):
			return false

		case let (.takeFromWorktop(lhsAddress, lhsAmount), .takeFromWorktop(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount

		case (.takeFromWorktop, _):
			return false

		case let (.takeNonFungiblesFromWorktop(lhsAddress, lhsIds), .takeNonFungiblesFromWorktop(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds

		case (.takeNonFungiblesFromWorktop, _):
			return false

		case let (.returnToWorktop(lhs), .returnToWorktop(rhs)):
			return lhs == rhs

		case (.returnToWorktop, _):
			return false

		case let (.assertWorktopContains(lhsAddress, lhsAmount), .assertWorktopContains(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount

		case (.assertWorktopContains, _):
			return false

		case let (.assertWorktopContainsNonFungibles(lhsAddress, lhsIds), .assertWorktopContainsNonFungibles(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds

		case (.assertWorktopContainsNonFungibles, _):
			return false

		case (.popFromAuthZone, .popFromAuthZone):
			dummy(.popFromAuthZone)
			return true

		case (.popFromAuthZone, _):
			return false

		case (.dropAuthZoneProofs, .dropAuthZoneProofs):
			dummy(.dropAuthZoneProofs)
			return true

		case (.dropAuthZoneProofs, _):
			return false

		case (.dropAuthZoneRegularProofs, .dropAuthZoneRegularProofs):
			dummy(.dropAuthZoneRegularProofs)
			return true

		case (.dropAuthZoneRegularProofs, _):
			return false

		case (.dropAuthZoneSignatureProofs, .dropAuthZoneSignatureProofs):
			dummy(.dropAuthZoneSignatureProofs)
			return true

		case (.dropAuthZoneSignatureProofs, _):
			return false

		case (.dropAllProofs, .dropAllProofs):
			dummy(.dropAllProofs)
			return true

		case (.dropAllProofs, _):
			return false

		case (.dropNamedProofs, .dropNamedProofs):
			dummy(.dropNamedProofs)
			return true

		case (.dropNamedProofs, _):
			return false

		case let (.pushToAuthZone(lhs), .pushToAuthZone(rhs)):
			return lhs == rhs

		case (.pushToAuthZone, _):
			return false

		case let (.createProofFromAuthZoneOfAmount(lhsAddress, lhsAmount), .createProofFromAuthZoneOfAmount(rhsAddress, rhsAmount)):
			return lhsAddress == rhsAddress && lhsAmount == rhsAmount

		case (.createProofFromAuthZoneOfAmount, _):
			return false

		case let (.createProofFromAuthZoneOfNonFungibles(lhsAddress, lhsIds), .createProofFromAuthZoneOfNonFungibles(rhsAddress, rhsIds)):
			return lhsAddress == rhsAddress && lhsIds == rhsIds

		case (.createProofFromAuthZoneOfNonFungibles, _):
			return false

		case let (.createProofFromAuthZoneOfAll(lhs), .createProofFromAuthZoneOfAll(rhs)):
			return lhs == rhs

		case (.createProofFromAuthZoneOfAll, _):
			return false

		case let (.burnResource(lhs), .burnResource(rhs)):
			return lhs == rhs

		case (.burnResource, _):
			return false

		case let (.cloneProof(lhs), .cloneProof(rhs)):
			return lhs == rhs

		case (.cloneProof, _):
			return false

		case let (.dropProof(lhs), .dropProof(rhs)):
			return lhs == rhs

		case (.dropProof, _):
			return false

		case let (.assertWorktopContainsAny(lhs), .assertWorktopContainsAny(rhs)):
			return lhs == rhs

		case (.assertWorktopContainsAny, _):
			return false

		case let (.createProofFromBucketOfAmount(lhsBucketId, lhsAmount), .createProofFromBucketOfAmount(rhsBucketId, rhsAmount)):
			return lhsBucketId == rhsBucketId && lhsAmount == rhsAmount

		case (.createProofFromBucketOfAmount, _):
			return false

		case let (.createProofFromBucketOfNonFungibles(lhsBucketId, lhsIds), .createProofFromBucketOfNonFungibles(rhsBucketId, rhsIds)):
			return lhsBucketId == rhsBucketId && lhsIds == rhsIds

		case (.createProofFromBucketOfNonFungibles, _):
			return false

		case let (.createProofFromBucketOfAll(lhs), .createProofFromBucketOfAll(rhs)):
			return lhs == rhs

		case (.createProofFromBucketOfAll, _):
			return false

		case let (.callFunction(lhsPackageAddress, lhsBlueprintName, lhsFunctionName, lhsArgs), .callFunction(rhsPackageAddress, rhsBlueprintName, rhsFunctionName, rhsArgs)):
			return lhsPackageAddress == rhsPackageAddress && lhsBlueprintName == rhsBlueprintName && lhsFunctionName == rhsFunctionName && lhsArgs == rhsArgs

		case (.callFunction, _):
			return false

		case let (.callMethod(lhsAddress, lhsMethodName, lhsArgs), .callMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callRoyaltyMethod(lhsAddress, lhsMethodName, lhsArgs), .callRoyaltyMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callMetadataMethod(lhsAddress, lhsMethodName, lhsArgs), .callMetadataMethod(rhsAddress, rhsMethodName, rhsArgs)),
		     let (.callRoleAssignmentMethod(lhsAddress, lhsMethodName, lhsArgs), .callRoleAssignmentMethod(rhsAddress, rhsMethodName, rhsArgs)):
			return lhsAddress == rhsAddress && lhsMethodName == rhsMethodName && lhsArgs == rhsArgs

		case (.callMethod, _):
			return false

		case (.callRoyaltyMethod, _):
			return false

		case (.callMetadataMethod, _):
			return false

		case (.callRoleAssignmentMethod, _):
			return false

		case let (.allocateGlobalAddress(lhsPackageAddress, lhsbBlueprintName), .allocateGlobalAddress(rhsPackageAddress, rhsBlueprintName)):
			return lhsPackageAddress == rhsPackageAddress && lhsbBlueprintName == rhsBlueprintName

		case (.allocateGlobalAddress, _):
			return false

		case let (.callDirectVaultMethod(lhsAddress, lhsMethodName, lhsArgs), .callDirectVaultMethod(rhsAddress, rhsMethodName, rhsArgs)):
			return lhsAddress == rhsAddress && lhsMethodName == rhsMethodName && lhsArgs == rhsArgs

		case (.callDirectVaultMethod, _):
			return false
		}
	}
}

// MARK: - ManifestValue + Hashable
extension ManifestValue: Hashable {
	public static func == (lhsOuter: ManifestValue, rhsOuter: ManifestValue) -> Bool {
		switch (lhsOuter, rhsOuter) {
		case let (.boolValue(lhs), .boolValue(rhs)):
			lhs == rhs
		case (.boolValue, _):
			false

		case let (.i8Value(lhs), .i8Value(rhs)):
			lhs == rhs
		case (.i8Value, _):
			false

		case let (.i16Value(lhs), .i16Value(rhs)):
			lhs == rhs
		case (.i16Value, _):
			false

		case let (.i32Value(lhs), .i32Value(rhs)):
			lhs == rhs
		case (.i32Value, _):
			false

		case let (.i64Value(lhs), .i64Value(rhs)):
			lhs == rhs
		case (.i64Value, _):
			false

		case let (.i128Value(lhs), .i128Value(rhs)):
			lhs == rhs
		case (.i128Value, _):
			false

		case let (.u8Value(lhs), .u8Value(rhs)):
			lhs == rhs
		case (.u8Value, _):
			false

		case let (.u16Value(lhs), .u16Value(rhs)):
			lhs == rhs
		case (.u16Value, _):
			false

		case let (.u32Value(lhs), .u32Value(rhs)):
			lhs == rhs
		case (.u32Value, _):
			false

		case let (.u64Value(lhs), .u64Value(rhs)):
			lhs == rhs
		case (.u64Value, _):
			false

		case let (.u128Value(lhs), .u128Value(rhs)):
			lhs == rhs
		case (.u128Value, _):
			false

		case let (.stringValue(lhs), .stringValue(rhs)):
			lhs == rhs
		case (.stringValue, _):
			false

		case let (.enumValue(lhsDiscriminator, lhsFields), .enumValue(rhsDiscriminator, rhsFields)):
			lhsDiscriminator == rhsDiscriminator && lhsFields == rhsFields
		case (.enumValue, _):
			false

		case let (.arrayValue(lhsElementValueKind, lhsElements), .arrayValue(rhsElementValueKind, rhsElements)):
			lhsElementValueKind == rhsElementValueKind && lhsElements == rhsElements
		case (.arrayValue, _):
			false

		case let (.tupleValue(lhs), .tupleValue(rhs)):
			lhs == rhs
		case (.tupleValue, _):
			false

		case let (.mapValue(lhsKeyValueKind, lhsValueValueKind, lhsEntries), .mapValue(rhsKeyValueKind, rhsValueValueKind, rhsEntries)):
			lhsKeyValueKind == rhsKeyValueKind && lhsValueValueKind == rhsValueValueKind && lhsEntries == rhsEntries
		case (.mapValue, _):
			false

		case let (.addressValue(lhs), .addressValue(rhs)):
			lhs == rhs
		case (.addressValue, _):
			false

		case let (.bucketValue(lhs), .bucketValue(rhs)):
			lhs == rhs
		case (.bucketValue, _):
			false

		case let (.proofValue(lhs), .proofValue(rhs)):
			lhs == rhs
		case (.proofValue, _):
			false

		case let (.expressionValue(lhs), .expressionValue(rhs)):
			lhs == rhs
		case (.expressionValue, _):
			false

		case let (.blobValue(lhs), .blobValue(rhs)):
			lhs == rhs
		case (.blobValue, _):
			false

		case let (.decimalValue(lhs), .decimalValue(rhs)):
			lhs == rhs
		case (.decimalValue, _):
			false

		case let (.preciseDecimalValue(lhs), .preciseDecimalValue(rhs)):
			lhs == rhs
		case (.preciseDecimalValue, _):
			false

		case let (.nonFungibleLocalIdValue(lhs), .nonFungibleLocalIdValue(rhs)):
			lhs == rhs
		case (.nonFungibleLocalIdValue, _):
			false

		case let (.addressReservationValue(lhs), .addressReservationValue(rhs)):
			lhs == rhs
		case (.addressReservationValue, _):
			false
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
		lhs.header() == rhs.header()
			&& lhs.manifest() == rhs.manifest()
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(header())
		hasher.combine(manifest())
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
		lhs.executionCost == rhs.executionCost
			&& lhs.finalizationCost == rhs.finalizationCost
			&& lhs.royaltyCost == rhs.royaltyCost
			&& lhs.storageExpansionCost == rhs.storageExpansionCost
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(executionCost)
		hasher.combine(finalizationCost)
		hasher.combine(royaltyCost)
		hasher.combine(storageExpansionCost)
	}
}

// MARK: - ResourceSpecifier + Hashable
extension ResourceSpecifier: Hashable {
	public static func == (lhs: ResourceSpecifier, rhs: ResourceSpecifier) -> Bool {
		switch (lhs, rhs) {
		case let (.amount(lhsResourceAddress, lhsAmount), .amount(rhsResourceAddress, rhsAmount)):
			lhsResourceAddress == rhsResourceAddress && lhsAmount == rhsAmount
		case let (.ids(lhsResourceAddress, lhsIds), .ids(rhsResourceAddress, rhsIds)):
			lhsResourceAddress == rhsResourceAddress && lhsIds == rhsIds

		case (.amount, _), (.ids, _):
			false
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

// MARK: - MetadataValue + Hashable
extension MetadataValue: Hashable {
	public static func == (lhs: MetadataValue, rhs: MetadataValue) -> Bool {
		switch (lhs, rhs) {
		case let (.stringValue(lhsValue), .stringValue(rhsValue)):
			lhsValue == rhsValue
		case (.stringValue, _):
			false

		case let (.boolValue(lhsValue), .boolValue(rhsValue)):
			lhsValue == rhsValue
		case (.boolValue, _):
			false

		case let (.u8Value(lhsValue), .u8Value(rhsValue)):
			lhsValue == rhsValue
		case (.u8Value, _):
			false

		case let (.u32Value(lhsValue), .u32Value(rhsValue)):
			lhsValue == rhsValue
		case (.u32Value, _):
			false

		case let (.u64Value(lhsValue), .u64Value(rhsValue)):
			lhsValue == rhsValue
		case (.u64Value, _):
			false

		case let (.i32Value(lhsValue), .i32Value(rhsValue)):
			lhsValue == rhsValue
		case (.i32Value, _):
			false

		case let (.i64Value(lhsValue), .i64Value(rhsValue)):
			lhsValue == rhsValue
		case (.i64Value, _):
			false

		case let (.decimalValue(lhsValue), .decimalValue(rhsValue)):
			lhsValue == rhsValue
		case (.decimalValue, _):
			false

		case let (.globalAddressValue(lhsValue), .globalAddressValue(rhsValue)):
			lhsValue == rhsValue
		case (.globalAddressValue, _):
			false

		case let (.publicKeyValue(lhsValue), .publicKeyValue(rhsValue)):
			lhsValue == rhsValue
		case (.publicKeyValue, _):
			false

		case let (.nonFungibleGlobalIdValue(lhsValue), .nonFungibleGlobalIdValue(rhsValue)):
			lhsValue == rhsValue
		case (.nonFungibleGlobalIdValue, _):
			false

		case let (.nonFungibleLocalIdValue(lhsValue), .nonFungibleLocalIdValue(rhsValue)):
			lhsValue == rhsValue
		case (.nonFungibleLocalIdValue, _):
			false

		case let (.instantValue(lhsValue), .instantValue(rhsValue)):
			lhsValue == rhsValue
		case (.instantValue, _):
			false

		case let (.urlValue(lhsValue), .urlValue(rhsValue)):
			lhsValue == rhsValue
		case (.urlValue, _):
			false

		case let (.originValue(lhsValue), .originValue(rhsValue)):
			lhsValue == rhsValue
		case (.originValue, _):
			false

		case let (.publicKeyHashValue(lhsValue), .publicKeyHashValue(rhsValue)):
			lhsValue == rhsValue
		case (.publicKeyHashValue, _):
			false

		case let (.stringArrayValue(lhsValue), .stringArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.stringArrayValue, _):
			false

		case let (.boolArrayValue(lhsValue), .boolArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.boolArrayValue, _):
			false

		case let (.u8ArrayValue(lhsValue), .u8ArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.u8ArrayValue, _):
			false

		case let (.u32ArrayValue(lhsValue), .u32ArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.u32ArrayValue, _):
			false

		case let (.u64ArrayValue(lhsValue), .u64ArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.u64ArrayValue, _):
			false

		case let (.i32ArrayValue(lhsValue), .i32ArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.i32ArrayValue, _):
			false

		case let (.i64ArrayValue(lhsValue), .i64ArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.i64ArrayValue, _):
			false

		case let (.decimalArrayValue(lhsValue), .decimalArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.decimalArrayValue, _):
			false

		case let (.globalAddressArrayValue(lhsValue), .globalAddressArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.globalAddressArrayValue, _):
			false

		case let (.publicKeyArrayValue(lhsValue), .publicKeyArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.publicKeyArrayValue, _):
			false

		case let (.nonFungibleGlobalIdArrayValue(lhsValue), .nonFungibleGlobalIdArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.nonFungibleGlobalIdArrayValue, _):
			false

		case let (.nonFungibleLocalIdArrayValue(lhsValue), .nonFungibleLocalIdArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.nonFungibleLocalIdArrayValue, _):
			false

		case let (.instantArrayValue(lhsValue), .instantArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.instantArrayValue, _):
			false

		case let (.urlArrayValue(lhsValue), .urlArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.urlArrayValue, _):
			false

		case let (.originArrayValue(lhsValue), .originArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.originArrayValue, _):
			false

		case let (.publicKeyHashArrayValue(lhsValue), .publicKeyHashArrayValue(rhsValue)):
			lhsValue == rhsValue
		case (.publicKeyHashArrayValue, _):
			false
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
			lhs == rhs
		case let (.static(lhs), .static(rhs)):
			lhs == rhs

		case (.named, _), (.static, _):
			false
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

// MARK: - ResourceOrNonFungible + Equatable
extension ResourceOrNonFungible: Equatable {
	public static func == (lhs: ResourceOrNonFungible, rhs: ResourceOrNonFungible) -> Bool {
		switch (lhs, rhs) {
		case let (.resource(lhsResource), .resource(rhsResource)):
			lhsResource == rhsResource
		case let (.nonFungible(lhsNonFungible), .nonFungible(rhsNonFungible)):
			lhsNonFungible == rhsNonFungible
		case (.resource, _), (.nonFungible, _):
			false
		}
	}
}

// MARK: - ResourceOrNonFungible + Hashable
extension ResourceOrNonFungible: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .resource(value):
			hasher.combine("Resource")
			hasher.combine(value)
		case let .nonFungible(value):
			hasher.combine("NonFungible")
			hasher.combine(value)
		}
	}
}
