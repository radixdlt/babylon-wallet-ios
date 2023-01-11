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

	case callNativeFunction(CallNativeFunction)
	case callNativeMethod(CallNativeMethod)

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

	case publishPackage(PublishPackageWithOwner)

	case createResource(CreateResource)
	case burnBucket(BurnBucket)
	case mintFungible(MintFungible)
}

// MARK: InstructionKind
public extension Instruction {
	var kind: InstructionKind {
		switch self {
		case .callFunction:
			return .callFunction

		case .callMethod:
			return .callMethod

		case .callNativeFunction:
			return .callNativeFunction

		case .callNativeMethod:
			return .callNativeMethod

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
			return .publishPackageWithOwner

		case .createResource:
			return .createResource

		case .burnBucket:
			return .burnBucket

		case .mintFungible:
			return .mintFungible
		}
	}
}

public extension Instruction {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		switch self {
		case let .callFunction(instruction):
			try instruction.encode(to: encoder)

		case let .callMethod(instruction):
			try instruction.encode(to: encoder)

		case let .callNativeFunction(instruction):
			try instruction.encode(to: encoder)

		case let .callNativeMethod(instruction):
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

		case let .createResource(instruction):
			try instruction.encode(to: encoder)

		case let .burnBucket(instruction):
			try instruction.encode(to: encoder)

		case let .mintFungible(instruction):
			try instruction.encode(to: encoder)
		}
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)

		switch kind {
		case .callFunction:
			self = try .callFunction(.init(from: decoder))

		case .callMethod:
			self = try .callMethod(.init(from: decoder))

		case .callNativeFunction:
			self = try .callNativeFunction(.init(from: decoder))

		case .callNativeMethod:
			self = try .callNativeMethod(.init(from: decoder))

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

		case .publishPackageWithOwner:
			self = try .publishPackage(.init(from: decoder))

		case .createResource:
			self = try .createResource(.init(from: decoder))

		case .burnBucket:
			self = try .burnBucket(.init(from: decoder))

		case .mintFungible:
			self = try .mintFungible(.init(from: decoder))
		}
	}
}
