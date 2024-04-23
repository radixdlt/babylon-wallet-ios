import Foundation
import Sargon

extension ThirdPartyDeposits {
	public func assetsExceptionSet() -> OrderedSet<AssetException> {
		assetsExceptionList.map(OrderedSet.init) ?? []
	}

	public func depositorsAllowSet() -> OrderedSet<ResourceOrNonFungible> {
		depositorsAllowList.map(OrderedSet.init) ?? []
	}

	/// Used on recovered account
	public static let unknown = Self(
		depositRule: .acceptAll,
		assetsExceptionList: nil,
		depositorsAllowList: nil
	)
}
