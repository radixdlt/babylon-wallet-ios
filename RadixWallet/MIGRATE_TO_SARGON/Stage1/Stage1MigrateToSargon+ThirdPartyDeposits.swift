import Foundation
import OrderedCollections
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
		guard var identifiedAssetsExceptions = assetsExceptionList?.asIdentified() else {
			assetsExceptionList = [new]
			return
		}
		identifiedAssetsExceptions.updateOrAppend(new)
		assetsExceptionList = identifiedAssetsExceptions.elements
	}

	public mutating func removeAllAssetsExceptions() {
		assetsExceptionList = []
	}

	public mutating func removeAllAllowedDepositors() {
		depositorsAllowList = []
	}

	public mutating func updateAssetsExceptionList(_ update: (inout AssetsExceptionList?) -> Void) {
		var identifiedExceptions = assetsExceptionList?.asIdentified()
		update(&identifiedExceptions)
		assetsExceptionList = identifiedExceptions?.elements
	}

	public mutating func updateDepositorsAllowList(_ update: (inout DepositorsAllowList?) -> Void) {
		var identifiedExceptions = depositorsAllowList?.asIdentified()
		update(&identifiedExceptions)
		depositorsAllowList = identifiedExceptions?.elements
	}

	public mutating func appendToDepositorsAllowList(_ new: ResourceOrNonFungible) {
		guard var identifiedAssetsExceptions = depositorsAllowList?.asIdentified() else {
			depositorsAllowList = [new]
			return
		}
		identifiedAssetsExceptions.updateOrAppend(new)
		depositorsAllowList = identifiedAssetsExceptions.elements
	}
}
