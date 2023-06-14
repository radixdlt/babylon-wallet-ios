import Foundation

// MARK: - InstructionProtocol
/// Simple protocol for instructions.
public protocol InstructionProtocol: Sendable, Codable, Hashable {
	static var kind: InstructionKind { get }
	func embed() -> Instruction
}

// MARK: - Instruction
public indirect enum Instruction: Sendable, Codable, Hashable {
	case callFunction(CallFunction)
	case callMethod(CallMethod)
	case callRoyaltyMethod(CallRoyaltyMethod)
	case callMetadataMethod(CallMetadataMethod)
	case callAccessRulesMethod(CallAccessRulesMethod)

	case takeAllFromWorktop(TakeAllFromWorktop)
	case takeFromWorktop(TakeFromWorktop)
	case takeNonFungiblesFromWorktop(TakeNonFungiblesFromWorktop)

	case returnToWorktop(ReturnToWorktop)

	case assertWorktopContains(AssertWorktopContains)
	case assertWorktopContainsByAmount(AssertWorktopContainsByAmount)
	case assertWorktopContainsNonFungibles(AssertWorktopContainsNonFungibles)

	case popFromAuthZone(PopFromAuthZone)
	case pushToAuthZone(PushToAuthZone)

	case clearAuthZone(ClearAuthZone)
	case clearSignatureProofs(ClearSignatureProofs)

	case createProofFromAuthZone(CreateProofFromAuthZone)
	case createProofFromAuthZoneOfAll(CreateProofFromAuthZoneOfAll)
	case createProofFromAuthZoneOfAmount(CreateProofFromAuthZoneOfAmount)
	case createProofFromAuthZoneOfNonFungibles(CreateProofFromAuthZoneOfNonFungibles)

	case createProofFromBucket(CreateProofFromBucket)
	case createProofFromBucketAll(CreateProofFromBucketAll)
	case createProofFromBucketOfAmount(CreateProofFromBucketOfAmount)
	case createProofFromBucketOfNonFungibles(CreateProofFromBucketOfNonFungibles)

	case cloneProof(CloneProof)
	case dropProof(DropProof)
	case dropAllProofs(DropAllProofs)

	case publishPackageAdvanced(PublishPackageAdvanced)
	case publishPackage(PublishPackage)

	case burnResource(BurnResource)
	case recallResource(RecallResource)

	case setMetadata(SetMetadata)
	case removeMetadata(RemoveMetadata)

	case setPackageRoyaltyConfig(SetPackageRoyaltyConfig)
	case setComponentRoyaltyConfig(SetComponentRoyaltyConfig)

	case claimPackageRoyalty(ClaimPackageRoyalty)
	case claimComponentRoyalty(ClaimComponentRoyalty)
	case setMethodAccessRule(SetMethodAccessRule)
	case setAuthorityAccessRule(SetAuthorityAccessRule)
	case setAuthorityMutability(SetAuthorityMutability)

	case mintFungible(MintFungible)
	case mintNonFungible(MintNonFungible)
	case mintUuidNonFungible(MintUuidNonFungible)

	case createFungibleResource(CreateFungibleResource)
	case createFungibleResourceWithInitialSupply(CreateFungibleResourceWithInitialSupply)
	case createNonFungibleResource(CreateNonFungibleResource)
	case createNonFungibleResourceWithInitialSupply(CreateNonFungibleResourceWithInitialSupply)

	case createAccessController(CreateAccessController)
	case createIdentityAdvanced(CreateIdentityAdvanced)
	case createIdentity(CreateIdentity)
	case assertAccessRule(AssertAccessRule)

	case createAccount(CreateAccount)
	case createAccountAdvanced(CreateAccountAdvanced)
	case createValidator(CreateValidator)
}

// MARK: InstructionKind

extension Instruction {
	public var kind: InstructionKind {
		switch self {
		case .callFunction:
			return .callFunction
		case .callMethod:
			return .callMethod
		case .callRoyaltyMethod:
			return .callRoyaltyMethod
		case .callMetadataMethod:
			return .callMetadataMethod
		case .callAccessRulesMethod:
			return .callAccessRulesMethod

		case .takeAllFromWorktop:
			return .takeAllFromWorktop
		case .takeFromWorktop:
			return .takeFromWorktop
		case .takeNonFungiblesFromWorktop:
			return .takeNonFungiblesFromWorktop

		case .returnToWorktop:
			return .returnToWorktop

		case .assertWorktopContains:
			return .assertWorktopContains
		case .assertWorktopContainsByAmount:
			return .assertWorktopContainsByAmount
		case .assertWorktopContainsNonFungibles:
			return .assertWorktopContainsNonFungibles

		case .popFromAuthZone:
			return .popFromAuthZone
		case .pushToAuthZone:
			return .pushToAuthZone

		case .clearAuthZone:
			return .clearAuthZone

		case .clearSignatureProofs:
			return .clearSignatureProofs

		case .createProofFromAuthZone:
			return .createProofFromAuthZone
		case .createProofFromAuthZoneOfAll:
			return .createProofFromAuthZoneOfAll
		case .createProofFromAuthZoneOfAmount:
			return .createProofFromAuthZoneOfAmount
		case .createProofFromAuthZoneOfNonFungibles:
			return .createProofFromAuthZoneOfNonFungibles

		case .createProofFromBucket:
			return .createProofFromBucket
		case .createProofFromBucketAll:
			return .createProofFromBucketAll
		case .createProofFromBucketOfAmount:
			return .createProofFromBucketOfAmount
		case .createProofFromBucketOfNonFungibles:
			return .createProofFromBucketOfNonFungibles

		case .cloneProof:
			return .cloneProof
		case .dropProof:
			return .dropProof
		case .dropAllProofs:
			return .dropAllProofs

		case .publishPackageAdvanced:
			return .publishPackageAdvanced
		case .publishPackage:
			return .publishPackage

		case .burnResource:
			return .burnResource
		case .recallResource:
			return .recallResource

		case .setMetadata:
			return .setMetadata
		case .removeMetadata:
			return .removeMetadata

		case .setPackageRoyaltyConfig:
			return .setPackageRoyaltyConfig
		case .setComponentRoyaltyConfig:
			return .setComponentRoyaltyConfig

		case .claimPackageRoyalty:
			return .claimPackageRoyalty
		case .claimComponentRoyalty:
			return .claimComponentRoyalty
		case .setMethodAccessRule:
			return .setMethodAccessRule
		case .setAuthorityAccessRule:
			return .setAuthorityAccessRule
		case .setAuthorityMutability:
			return .setAuthorityMutability

		case .mintFungible:
			return .mintFungible
		case .mintNonFungible:
			return .mintNonFungible
		case .mintUuidNonFungible:
			return .mintUuidNonFungible

		case .createFungibleResource:
			return .createFungibleResource
		case .createFungibleResourceWithInitialSupply:
			return .createFungibleResourceWithInitialSupply
		case .createNonFungibleResourceWithInitialSupply:
			return .createNonFungibleResourceWithInitialSupply
		case .createNonFungibleResource:
			return .createNonFungibleResource

		case .createAccessController:
			return .createAccessController
		case .createIdentity:
			return .createIdentity
		case .createIdentityAdvanced:
			return .createIdentityAdvanced
		case .assertAccessRule:
			return .assertAccessRule

		case .createAccount:
			return .createAccount
		case .createAccountAdvanced:
			return .createAccountAdvanced

		case .createValidator:
			return .createValidator
		}
	}
}

extension Instruction {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .callFunction(instruction):
			try instruction.encode(to: encoder)
		case let .callMethod(instruction):
			try instruction.encode(to: encoder)
		case let .callRoyaltyMethod(instruction):
			try instruction.encode(to: encoder)
		case let .callMetadataMethod(instruction):
			try instruction.encode(to: encoder)
		case let .callAccessRulesMethod(instruction):
			try instruction.encode(to: encoder)

		case let .takeAllFromWorktop(instruction):
			try instruction.encode(to: encoder)
		case let .takeFromWorktop(instruction):
			try instruction.encode(to: encoder)
		case let .takeNonFungiblesFromWorktop(instruction):
			try instruction.encode(to: encoder)

		case let .returnToWorktop(instruction):
			try instruction.encode(to: encoder)

		case let .assertWorktopContains(instruction):
			try instruction.encode(to: encoder)
		case let .assertWorktopContainsByAmount(instruction):
			try instruction.encode(to: encoder)
		case let .assertWorktopContainsNonFungibles(instruction):
			try instruction.encode(to: encoder)

		case let .popFromAuthZone(instruction):
			try instruction.encode(to: encoder)
		case let .pushToAuthZone(instruction):
			try instruction.encode(to: encoder)

		case let .clearAuthZone(instruction):
			try instruction.encode(to: encoder)

		case let .clearSignatureProofs(instruction):
			try instruction.encode(to: encoder)

		case let .createProofFromAuthZone(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromAuthZoneOfAll(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromAuthZoneOfAmount(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromAuthZoneOfNonFungibles(instruction):
			try instruction.encode(to: encoder)

		case let .createProofFromBucket(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromBucketAll(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromBucketOfAmount(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromBucketOfNonFungibles(instruction):
			try instruction.encode(to: encoder)

		case let .cloneProof(instruction):
			try instruction.encode(to: encoder)
		case let .dropProof(instruction):
			try instruction.encode(to: encoder)
		case let .dropAllProofs(instruction):
			try instruction.encode(to: encoder)

		case let .publishPackageAdvanced(instruction):
			try instruction.encode(to: encoder)
		case let .publishPackage(instruction):
			try instruction.encode(to: encoder)

		case let .burnResource(instruction):
			try instruction.encode(to: encoder)
		case let .recallResource(instruction):
			try instruction.encode(to: encoder)

		case let .setMetadata(instruction):
			try instruction.encode(to: encoder)
		case let .removeMetadata(instruction):
			try instruction.encode(to: encoder)

		case let .setPackageRoyaltyConfig(instruction):
			try instruction.encode(to: encoder)
		case let .setComponentRoyaltyConfig(instruction):
			try instruction.encode(to: encoder)

		case let .claimPackageRoyalty(instruction):
			try instruction.encode(to: encoder)
		case let .claimComponentRoyalty(instruction):
			try instruction.encode(to: encoder)
		case let .setMethodAccessRule(instruction):
			try instruction.encode(to: encoder)
		case let .setAuthorityAccessRule(instruction):
			try instruction.encode(to: encoder)
		case let .setAuthorityMutability(instruction):
			try instruction.encode(to: encoder)

		case let .mintFungible(instruction):
			try instruction.encode(to: encoder)
		case let .mintNonFungible(instruction):
			try instruction.encode(to: encoder)
		case let .mintUuidNonFungible(instruction):
			try instruction.encode(to: encoder)

		case let .createFungibleResource(instruction):
			try instruction.encode(to: encoder)
		case let .createFungibleResourceWithInitialSupply(instruction):
			try instruction.encode(to: encoder)
		case let .createNonFungibleResource(instruction):
			try instruction.encode(to: encoder)
		case let .createNonFungibleResourceWithInitialSupply(instruction):
			try instruction.encode(to: encoder)

		case let .createAccessController(instruction):
			try instruction.encode(to: encoder)
		case let .createIdentity(instruction):
			try instruction.encode(to: encoder)
		case let .createIdentityAdvanced(instruction):
			try instruction.encode(to: encoder)
		case let .assertAccessRule(instruction):
			try instruction.encode(to: encoder)

		case let .createAccount(instruction):
			try instruction.encode(to: encoder)
		case let .createAccountAdvanced(instruction):
			try instruction.encode(to: encoder)

		case let .createValidator(instruction):
			try instruction.encode(to: encoder)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)

		switch kind {
		case .callFunction:
			self = try .callFunction(.init(from: decoder))
		case .callMethod:
			self = try .callMethod(.init(from: decoder))
		case .callRoyaltyMethod:
			self = try .callRoyaltyMethod(.init(from: decoder))
		case .callMetadataMethod:
			self = try .callMetadataMethod(.init(from: decoder))
		case .callAccessRulesMethod:
			self = try .callAccessRulesMethod(.init(from: decoder))

		case .takeAllFromWorktop:
			self = try .takeAllFromWorktop(.init(from: decoder))
		case .takeFromWorktop:
			self = try .takeFromWorktop(.init(from: decoder))
		case .takeNonFungiblesFromWorktop:
			self = try .takeNonFungiblesFromWorktop(.init(from: decoder))

		case .returnToWorktop:
			self = try .returnToWorktop(.init(from: decoder))

		case .assertWorktopContains:
			self = try .assertWorktopContains(.init(from: decoder))
		case .assertWorktopContainsByAmount:
			self = try .assertWorktopContainsByAmount(.init(from: decoder))
		case .assertWorktopContainsNonFungibles:
			self = try .assertWorktopContainsNonFungibles(.init(from: decoder))

		case .popFromAuthZone:
			self = try .popFromAuthZone(.init(from: decoder))
		case .pushToAuthZone:
			self = try .pushToAuthZone(.init(from: decoder))

		case .clearAuthZone:
			self = try .clearAuthZone(.init(from: decoder))

		case .clearSignatureProofs:
			self = try .clearSignatureProofs(.init(from: decoder))

		case .createProofFromAuthZone:
			self = try .createProofFromAuthZone(.init(from: decoder))
		case .createProofFromAuthZoneOfAll:
			self = try .createProofFromAuthZoneOfAll(.init(from: decoder))
		case .createProofFromAuthZoneOfAmount:
			self = try .createProofFromAuthZoneOfAmount(.init(from: decoder))
		case .createProofFromAuthZoneOfNonFungibles:
			self = try .createProofFromAuthZoneOfNonFungibles(.init(from: decoder))

		case .createProofFromBucket:
			self = try .createProofFromBucket(.init(from: decoder))
		case .createProofFromBucketAll:
			self = try .createProofFromBucketAll(.init(from: decoder))
		case .createProofFromBucketOfAmount:
			self = try .createProofFromBucketOfAmount(.init(from: decoder))
		case .createProofFromBucketOfNonFungibles:
			self = try .createProofFromBucketOfNonFungibles(.init(from: decoder))

		case .cloneProof:
			self = try .cloneProof(.init(from: decoder))
		case .dropProof:
			self = try .dropProof(.init(from: decoder))
		case .dropAllProofs:
			self = try .dropAllProofs(.init(from: decoder))

		case .publishPackageAdvanced:
			self = try .publishPackageAdvanced(.init(from: decoder))
		case .publishPackage:
			self = try .publishPackage(.init(from: decoder))

		case .burnResource:
			self = try .burnResource(.init(from: decoder))
		case .recallResource:
			self = try .recallResource(.init(from: decoder))

		case .setMetadata:
			self = try .setMetadata(.init(from: decoder))
		case .removeMetadata:
			self = try .removeMetadata(.init(from: decoder))

		case .setPackageRoyaltyConfig:
			self = try .setPackageRoyaltyConfig(.init(from: decoder))
		case .setComponentRoyaltyConfig:
			self = try .setComponentRoyaltyConfig(.init(from: decoder))

		case .claimPackageRoyalty:
			self = try .claimPackageRoyalty(.init(from: decoder))
		case .claimComponentRoyalty:
			self = try .claimComponentRoyalty(.init(from: decoder))
		case .setMethodAccessRule:
			self = try .setMethodAccessRule(.init(from: decoder))
		case .setAuthorityAccessRule:
			self = try .setAuthorityAccessRule(.init(from: decoder))
		case .setAuthorityMutability:
			self = try .setAuthorityMutability(.init(from: decoder))

		case .mintFungible:
			self = try .mintFungible(.init(from: decoder))
		case .mintNonFungible:
			self = try .mintNonFungible(.init(from: decoder))
		case .mintUuidNonFungible:
			self = try .mintUuidNonFungible(.init(from: decoder))

		case .createFungibleResource:
			self = try .createFungibleResource(.init(from: decoder))
		case .createFungibleResourceWithInitialSupply:
			self = try .createFungibleResourceWithInitialSupply(.init(from: decoder))
		case .createNonFungibleResource:
			self = try .createNonFungibleResource(.init(from: decoder))
		case .createNonFungibleResourceWithInitialSupply:
			self = try .createNonFungibleResourceWithInitialSupply(.init(from: decoder))

		case .createAccessController:
			self = try .createAccessController(.init(from: decoder))
		case .createIdentity:
			self = try .createIdentity(.init(from: decoder))
		case .createIdentityAdvanced:
			self = try .createIdentityAdvanced(.init(from: decoder))
		case .assertAccessRule:
			self = try .assertAccessRule(.init(from: decoder))

		case .createAccount:
			self = try .createAccount(.init(from: decoder))
		case .createAccountAdvanced:
			self = try .createAccountAdvanced(.init(from: decoder))

		case .createValidator:
			self = try .createValidator(.init(from: decoder))
		}
	}
}
