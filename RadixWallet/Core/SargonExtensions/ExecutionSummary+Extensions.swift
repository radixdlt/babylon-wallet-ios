import Sargon

extension ExecutionSummary {
	var detailedManifestClass: DetailedManifestClass? {
		self.detailedClassification.first
	}
}
