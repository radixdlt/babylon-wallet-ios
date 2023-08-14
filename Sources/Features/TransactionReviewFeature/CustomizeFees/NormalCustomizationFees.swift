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
}
