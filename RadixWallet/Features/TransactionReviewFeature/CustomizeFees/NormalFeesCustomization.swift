import ComposableArchitecture
import SwiftUI

struct NormalFeesCustomization: FeatureReducer {
	struct State: Hashable, Sendable {
		let fees: TransactionFee.NormalFeeCustomization

		init(
			fees: TransactionFee.NormalFeeCustomization
		) {
			self.fees = fees
		}
	}

	/// For now no logic here, but normal mode in the future will allow users to select from predefined Tip fees.
}
