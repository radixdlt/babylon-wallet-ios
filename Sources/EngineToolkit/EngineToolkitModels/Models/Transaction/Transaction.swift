import Cryptography
import Prelude

// MARK: - TransactionManifest
public struct TransactionManifest: Sendable, Codable, Hashable {
	// MARK: Stored properties
	public let instructions: ManifestInstructions
	public let blobs: [[UInt8]]

	// MARK: Init

	public init(
		instructions: ManifestInstructions,
		blobs: [[UInt8]] = []
	) {
		self.instructions = instructions
		self.blobs = blobs
	}

	public init(
		instructions: [Instruction],
		blobs: [[UInt8]] = []
	) {
		self.init(
			instructions: .parsed(instructions),
			blobs: blobs
		)
	}

	public init(
		instructions: [any InstructionProtocol],
		blobs: [[UInt8]] = []
	) {
		self.init(
			instructions: instructions.map { $0.embed() },
			blobs: blobs
		)
	}
}

// MARK: - InstructionsBuilder
@resultBuilder
public struct InstructionsBuilder {}
public extension InstructionsBuilder {
	static func buildBlock(_ instructions: Instruction...) -> [Instruction] {
		instructions
	}

	static func buildBlock(_ instruction: Instruction) -> [Instruction] {
		[instruction]
	}

	static func buildBlock(_ instruction: Instruction) -> Instruction {
		instruction
	}
}

// MARK: - SpecificInstructionsBuilder
@resultBuilder
public struct SpecificInstructionsBuilder {}
public extension SpecificInstructionsBuilder {
	static func buildBlock(_ instructions: any InstructionProtocol...) -> [any InstructionProtocol] {
		instructions
	}

	static func buildBlock(_ instruction: any InstructionProtocol) -> [any InstructionProtocol] {
		[instruction]
	}

	static func buildBlock(_ instruction: any InstructionProtocol) -> any InstructionProtocol {
		instruction
	}
}

public extension TransactionManifest {
	init(@InstructionsBuilder buildInstructions: () throws -> [Instruction]) rethrows {
		try self.init(instructions: buildInstructions())
	}

	init(@SpecificInstructionsBuilder buildInstructions: () throws -> [any InstructionProtocol]) rethrows {
		try self.init(instructions: buildInstructions())
	}
}
