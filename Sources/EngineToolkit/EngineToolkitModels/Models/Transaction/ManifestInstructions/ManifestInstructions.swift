import Foundation

// MARK: - ManifestInstructions
public enum ManifestInstructions: Sendable, Codable, Hashable, CustomStringConvertible {
	// ==============
	// Enum Variants
	// ==============

	case string(String)
	case parsed([Instruction])
}

// MARK: ManifestInstructions.Kind
extension ManifestInstructions {
	public enum Kind: String, Codable, Hashable, Sendable {
		case string = "String"
		case parsed = "Parsed"
	}
}

public typealias ManifestInstructionsKind = ManifestInstructions.Kind

extension ManifestInstructions {
	@available(iOS, deprecated: 999, message: "Prefer using `String(describing: transactionManifest)` if you have that, which will result in much better printing.")
	@available(macOS, deprecated: 999, message: "Prefer using `String(describing: transactionManifest)` if you have that, which will result in much better printing.")
	public var description: String {
		switch self {
		case let .string(string):
			return string
		case let .parsed(instructions):
			return instructions.lazy.map { String(describing: $0) }.joined(separator: "\n")
		}
	}
}
