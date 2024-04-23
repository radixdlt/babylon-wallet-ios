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

	public mutating func appendToAssetsExceptionList(_ new: AssetException) {
		if assetsExceptionList == nil {
			assetsExceptionList = [new]
		} else {
			assetsExceptionList!.updateOrAppend(new)
		}
	}

	public mutating func removeAllAssetsExceptions() {
		assetsExceptionList = []
	}

	public mutating func removeAllAllowedDepositors() {
		depositorsAllowList = []
	}

	public mutating func updateAssetsExceptionList(_ update: (inout AssetsExceptionList?) -> Void) {
		update(&self.assetsExceptionList)
	}

	public mutating func updateDepositorsAllowList(_ update: (inout DepositorsAllowList?) -> Void) {
		update(&self.depositorsAllowList)
	}

	public mutating func appendToDepositorsAllowList(_ new: ResourceOrNonFungible) {
		if depositorsAllowList == nil {
			depositorsAllowList = [new]
		} else {
			depositorsAllowList!.updateOrAppend(new)
		}
	}
}
