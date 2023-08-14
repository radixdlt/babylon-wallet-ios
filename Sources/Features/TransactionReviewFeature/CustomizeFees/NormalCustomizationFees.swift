import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

public struct NormalCustomizationFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		let fees: TransactionFee.NormalFeeCustomization

		init(
			fees: TransactionFee.NormalFeeCustomization
		) {
			self.fees = fees
		}
	}

	/// For now no logic here, but normal mode in the future will allow users to select from predefined Tip fees.
}
