import EngineKit
import FeaturePrelude
import Foundation
import TransactionClient

public struct NormalCustomizationFees: FeatureReducer {
	public struct State: Hashable, Sendable {
		var normalCustomization: TransactionFee.NormalFeeCustomization

		init(
			normalCustomization: TransactionFee.NormalFeeCustomization
		) {
			self.normalCustomization = normalCustomization
		}
	}

	/// For now no logic here, but normal mode in the future will allow users to select from predefined Tip fees.
}
