import Foundation
import Sargon

extension OnLedgerSettings {
	public static let unknown = Self(thirdPartyDeposits: .unknown)
}

extension ThirdPartyDeposits {
	/// Used on recovered account
	public static let unknown = Self(
		depositRule: .acceptAll,
		assetsExceptionList: nil,
		depositorsAllowList: nil
	)
}
