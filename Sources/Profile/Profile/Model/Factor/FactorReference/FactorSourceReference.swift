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
