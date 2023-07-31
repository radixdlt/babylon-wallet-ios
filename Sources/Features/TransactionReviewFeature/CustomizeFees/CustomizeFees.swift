import EngineKit
import FeaturePrelude
import TransactionClient

struct CustomizeFees: FeatureReducer {
	struct State: Hashable, Sendable {
		var feePayer: FeePayerCandiate
		var feeSummary: FeeSummary
		let feeLocks: FeeLocks
	}
}
