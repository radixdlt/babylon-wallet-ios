import Sargon

extension ExecutionSummary {
	var detailedManifestClass: DetailedManifestClass {
		self.detailedClassification.first!
	}
}

// MARK: - NonFungibleGlobalID + CustomStringConvertible
extension NonFungibleGlobalID: CustomStringConvertible {
	public var description: String {
		fatalError("Sargon migration")
	}
}
