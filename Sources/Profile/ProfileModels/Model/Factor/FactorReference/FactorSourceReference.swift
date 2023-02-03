import Prelude

// MARK: - FactorSourceReference
/// Just a reference to a factor source, identifiable a stable ID and hint of the factor source kind.
public struct FactorSourceReference:
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// The kind of factor source
	public let factorSourceKind: FactorSourceKind

	/// A string convertible **unique** and **stable** identifier for this factor source.
	/// It may
	public let factorSourceID: FactorSourceID

	public init(factorSourceKind: FactorSourceKind, factorSourceID: FactorSourceID) {
		self.factorSourceKind = factorSourceKind
		self.factorSourceID = factorSourceID
	}
}

public extension FactorSourceReference {
	/// A stable and unique ID
	var id: String {
		"id=\(factorSourceID.data.hex())&kind=\(factorSourceKind.rawValue)"
	}
}

public extension FactorSourceReference {
	var customDumpMirror: Mirror {
		.init(self, children: [
			"factorSourceKind": factorSourceKind,
			"factorSourceID": factorSourceID,
		])
	}

	var description: String {
		"""
		"factorSourceKind": \(factorSourceKind),
		"factorSourceID": \(factorSourceID),
		"""
	}
}

#if DEBUG
public extension FactorSourceReference {
	static let previewValue: Self = .init(
		factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
		factorSourceID: .init(stringLiteral: "4d8b07d0220a9b838b7626dc917b96512abc629bd912a66f60c942fc5fa2f287")
	)
}
#endif
