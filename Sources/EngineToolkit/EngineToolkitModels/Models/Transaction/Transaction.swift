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
extension InstructionsBuilder {
	public static func buildBlock(_ instructions: Instruction...) -> [Instruction] {
		instructions
	}

	public static func buildBlock(_ instruction: Instruction) -> [Instruction] {
		[instruction]
	}

	public static func buildBlock(_ instruction: Instruction) -> Instruction {
		instruction
	}
}

// MARK: - SpecificInstructionsBuilder
@resultBuilder
public struct SpecificInstructionsBuilder {}
extension SpecificInstructionsBuilder {
	public static func buildBlock(_ instructions: any InstructionProtocol...) -> [any InstructionProtocol] {
		instructions
	}

	public static func buildBlock(_ instruction: any InstructionProtocol) -> [any InstructionProtocol] {
		[instruction]
	}

	public static func buildBlock(_ instruction: any InstructionProtocol) -> any InstructionProtocol {
		instruction
	}
}

extension TransactionManifest {
	public init(@InstructionsBuilder buildInstructions: () throws -> [Instruction]) rethrows {
		try self.init(instructions: buildInstructions())
	}

	public init(@SpecificInstructionsBuilder buildInstructions: () throws -> [any InstructionProtocol]) rethrows {
		try self.init(instructions: buildInstructions())
	}
}
