import CasePaths
import Foundation

// MARK: - Array_
public struct Array_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .array
	public static let casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.array

	// MARK: Stored properties

	public let elementKind: ManifestASTValueKind
	public let elements: [ManifestASTValue]

	// MARK: Init

	public init(
		elementKind: ManifestASTValueKind,
		elements: [ManifestASTValue]
	) throws {
		self.elementKind = elementKind
		self.elements = elements
	}

	public init(
		elementKind: ManifestASTValueKind,
		@ValuesBuilder buildValues: () throws -> [any ValueProtocol]
	) throws {
		try self.init(
			elementKind: elementKind,
			elements: buildValues().map { $0.embedValue() }
		)
	}

	#if swift(<5.8)
	public init(
		elementKind: ManifestASTValueKind,
		@SpecificValuesBuilder buildValues: () throws -> [ManifestASTValue]
	) throws {
		try self.init(
			elementKind: elementKind,
			elements: buildValues()
		)
	}
	#endif
}

// MARK: Array_.Error
extension Array_ {
	public enum Error: String, Swift.Error, Sendable, Hashable {
		case homogeneousArrayRequired
	}
}

extension Array_ {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case elements, elementKind = "element_kind"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(elements, forKey: .elements)
		try container.encode(elementKind, forKey: .elementKind)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			elementKind: container.decode(ManifestASTValueKind.self, forKey: .elementKind),
			elements: container.decode([ManifestASTValue].self, forKey: .elements)
		)
	}
}
