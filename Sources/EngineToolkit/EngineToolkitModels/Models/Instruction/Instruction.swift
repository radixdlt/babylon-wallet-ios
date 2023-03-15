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

	case takeFromWorktop(TakeFromWorktop)
	case takeFromWorktopByAmount(TakeFromWorktopByAmount)
	case takeFromWorktopByIds(TakeFromWorktopByIds)

	case returnToWorktop(ReturnToWorktop)

	case assertWorktopContains(AssertWorktopContains)
	case assertWorktopContainsByAmount(AssertWorktopContainsByAmount)
	case assertWorktopContainsByIds(AssertWorktopContainsByIds)

	case popFromAuthZone(PopFromAuthZone)
	case pushToAuthZone(PushToAuthZone)

	case clearAuthZone(ClearAuthZone)

	case createProofFromAuthZone(CreateProofFromAuthZone)
	case createProofFromAuthZoneByAmount(CreateProofFromAuthZoneByAmount)
	case createProofFromAuthZoneByIds(CreateProofFromAuthZoneByIds)

	case createProofFromBucket(CreateProofFromBucket)

	case cloneProof(CloneProof)
	case dropProof(DropProof)
	case dropAllProofs(DropAllProofs)

	case publishPackage(PublishPackage)

	case burnResource(BurnResource)
	case recallResource(RecallResource)

	case setMetadata(SetMetadata)

	case setPackageRoyaltyConfig(SetPackageRoyaltyConfig)
	case setComponentRoyaltyConfig(SetComponentRoyaltyConfig)

	case claimPackageRoyalty(ClaimPackageRoyalty)
	case claimComponentRoyalty(ClaimComponentRoyalty)
	case setMethodAccessRule(SetMethodAccessRule)

	case mintFungible(MintFungible)
	case mintNonFungible(MintNonFungible)
	case mintUuidNonFungible(MintUuidNonFungible)

	case createFungibleResource(CreateFungibleResource)
	case createFungibleResourceWithInitialSupply(CreateFungibleResourceWithInitialSupply)
	case createNonFungibleResource(CreateNonFungibleResource)
	case createNonFungibleResourceWithInitialSupply(CreateNonFungibleResourceWithInitialSupply)

	case createAccessController(CreateAccessController)
	case createIdentity(CreateIdentity)
	case assertAccessRule(AssertAccessRule)

	case createAccount(CreateAccount)
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

		case .takeFromWorktop:
			return .takeFromWorktop
		case .takeFromWorktopByAmount:
			return .takeFromWorktopByAmount
		case .takeFromWorktopByIds:
			return .takeFromWorktopByIds

		case .returnToWorktop:
			return .returnToWorktop

		case .assertWorktopContains:
			return .assertWorktopContains
		case .assertWorktopContainsByAmount:
			return .assertWorktopContainsByAmount
		case .assertWorktopContainsByIds:
			return .assertWorktopContainsByIds

		case .popFromAuthZone:
			return .popFromAuthZone
		case .pushToAuthZone:
			return .pushToAuthZone

		case .clearAuthZone:
			return .clearAuthZone

		case .createProofFromAuthZone:
			return .createProofFromAuthZone
		case .createProofFromAuthZoneByAmount:
			return .createProofFromAuthZoneByAmount
		case .createProofFromAuthZoneByIds:
			return .createProofFromAuthZoneByIds

		case .createProofFromBucket:
			return .createProofFromBucket

		case .cloneProof:
			return .cloneProof
		case .dropProof:
			return .dropProof
		case .dropAllProofs:
			return .dropAllProofs

		case .publishPackage:
			return .publishPackage

		case .burnResource:
			return .burnResource
		case .recallResource:
			return .recallResource

		case .setMetadata:
			return .setMetadata

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
		case .assertAccessRule:
			return .assertAccessRule

		case .createAccount:
			return .createAccount

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

		case let .takeFromWorktop(instruction):
			try instruction.encode(to: encoder)
		case let .takeFromWorktopByAmount(instruction):
			try instruction.encode(to: encoder)
		case let .takeFromWorktopByIds(instruction):
			try instruction.encode(to: encoder)

		case let .returnToWorktop(instruction):
			try instruction.encode(to: encoder)

		case let .assertWorktopContains(instruction):
			try instruction.encode(to: encoder)
		case let .assertWorktopContainsByAmount(instruction):
			try instruction.encode(to: encoder)
		case let .assertWorktopContainsByIds(instruction):
			try instruction.encode(to: encoder)

		case let .popFromAuthZone(instruction):
			try instruction.encode(to: encoder)
		case let .pushToAuthZone(instruction):
			try instruction.encode(to: encoder)

		case let .clearAuthZone(instruction):
			try instruction.encode(to: encoder)

		case let .createProofFromAuthZone(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromAuthZoneByAmount(instruction):
			try instruction.encode(to: encoder)
		case let .createProofFromAuthZoneByIds(instruction):
			try instruction.encode(to: encoder)

		case let .createProofFromBucket(instruction):
			try instruction.encode(to: encoder)

		case let .cloneProof(instruction):
			try instruction.encode(to: encoder)
		case let .dropProof(instruction):
			try instruction.encode(to: encoder)
		case let .dropAllProofs(instruction):
			try instruction.encode(to: encoder)

		case let .publishPackage(instruction):
			try instruction.encode(to: encoder)

		case let .burnResource(instruction):
			try instruction.encode(to: encoder)
		case let .recallResource(instruction):
			try instruction.encode(to: encoder)

		case let .setMetadata(instruction):
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
		case let .assertAccessRule(instruction):
			try instruction.encode(to: encoder)

		case let .createAccount(instruction):
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

		case .takeFromWorktop:
			self = try .takeFromWorktop(.init(from: decoder))
		case .takeFromWorktopByAmount:
			self = try .takeFromWorktopByAmount(.init(from: decoder))
		case .takeFromWorktopByIds:
			self = try .takeFromWorktopByIds(.init(from: decoder))

		case .returnToWorktop:
			self = try .returnToWorktop(.init(from: decoder))

		case .assertWorktopContains:
			self = try .assertWorktopContains(.init(from: decoder))
		case .assertWorktopContainsByAmount:
			self = try .assertWorktopContainsByAmount(.init(from: decoder))
		case .assertWorktopContainsByIds:
			self = try .assertWorktopContainsByIds(.init(from: decoder))

		case .popFromAuthZone:
			self = try .popFromAuthZone(.init(from: decoder))
		case .pushToAuthZone:
			self = try .pushToAuthZone(.init(from: decoder))

		case .clearAuthZone:
			self = try .clearAuthZone(.init(from: decoder))

		case .createProofFromAuthZone:
			self = try .createProofFromAuthZone(.init(from: decoder))
		case .createProofFromAuthZoneByAmount:
			self = try .createProofFromAuthZoneByAmount(.init(from: decoder))
		case .createProofFromAuthZoneByIds:
			self = try .createProofFromAuthZoneByIds(.init(from: decoder))

		case .createProofFromBucket:
			self = try .createProofFromBucket(.init(from: decoder))

		case .cloneProof:
			self = try .cloneProof(.init(from: decoder))
		case .dropProof:
			self = try .dropProof(.init(from: decoder))
		case .dropAllProofs:
			self = try .dropAllProofs(.init(from: decoder))

		case .publishPackage:
			self = try .publishPackage(.init(from: decoder))

		case .burnResource:
			self = try .burnResource(.init(from: decoder))
		case .recallResource:
			self = try .recallResource(.init(from: decoder))

		case .setMetadata:
			self = try .setMetadata(.init(from: decoder))

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
		case .assertAccessRule:
			self = try .assertAccessRule(.init(from: decoder))

		case .createAccount:
			self = try .createAccount(.init(from: decoder))

		case .createValidator:
			self = try .createValidator(.init(from: decoder))
		}
	}
}
