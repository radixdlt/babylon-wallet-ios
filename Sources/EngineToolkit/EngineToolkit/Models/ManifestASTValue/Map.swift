import Foundation

// MARK: - Map_
public struct Map_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .map
	public func embedValue() -> ManifestASTValue {
		.map(self)
	}

	// MARK: Stored properties
	public typealias Entries = [[ManifestASTValue]]

	public let keyKind: ManifestASTValueKind
	public let valueKind: ManifestASTValueKind
	public let entries: Entries

	// MARK: Init

	public init(
		keyKind: ManifestASTValueKind,
		valueKind: ManifestASTValueKind,
		entries: Entries
	) {
		self.keyKind = keyKind
		self.valueKind = valueKind
		self.entries = entries
	}
}

// MARK: Map_.Error
public extension Map_ {
	enum Error: String, Swift.Error, Sendable, Hashable {
		case homogeneousMapRequired
	}
}

extension Map_ {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case kind
		case entries
		case keyKind = "key_kind"
		case valueKind = "value_kind"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)

		try container.encode(keyKind, forKey: .keyKind)
		try container.encode(valueKind, forKey: .valueKind)

		try container.encode(entries, forKey: .entries) // TODO: Fix map
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let entries = try container.decode(Entries.self, forKey: .entries)
		let keyKind = try container.decode(ManifestASTValueKind.self, forKey: .keyKind)
		let valueKind = try container.decode(ManifestASTValueKind.self, forKey: .valueKind)

		self.init(
			keyKind: keyKind, valueKind: valueKind, entries: entries
		)
	}
}
