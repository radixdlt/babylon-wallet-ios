import Sargon

extension ExecutionSummary {
	var detailedManifestClass: DetailedManifestClass? {
		// We favor more specific classifications.
		// Also, RET started to put General classification first in the list, instead of last.
		let firstNonGeneral = self.detailedClassification.first { $0 != .general }
		return firstNonGeneral ?? self.detailedClassification.first
	}
}
