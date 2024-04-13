import Foundation
import Sargon

extension ThirdPartyDeposits {
	public var isAssetsExceptionsUnknown: Bool {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var isAllowedDepositorsUnknown: Bool {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
