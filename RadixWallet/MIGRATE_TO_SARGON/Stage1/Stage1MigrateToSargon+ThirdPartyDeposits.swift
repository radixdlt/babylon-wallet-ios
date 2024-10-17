import Foundation
import OrderedCollections
import Sargon

extension ThirdPartyDeposits {
	func assetsExceptionSet() -> OrderedSet<AssetException> {
		assetsExceptionList.map(OrderedSet.init) ?? []
	}

	func depositorsAllowSet() -> OrderedSet<ResourceOrNonFungible> {
		depositorsAllowList.map(OrderedSet.init) ?? []
	}

	/// Used on recovered account
	static let unknown = Self(
		depositRule: .acceptAll,
		assetsExceptionList: nil,
		depositorsAllowList: nil
	)

	mutating func appendToAssetsExceptionList(_ new: AssetException) {
		guard var identifiedAssetsExceptions = assetsExceptionList?.asIdentified() else {
			assetsExceptionList = [new]
			return
		}
		identifiedAssetsExceptions.updateOrAppend(new)
		assetsExceptionList = identifiedAssetsExceptions.elements
	}

	mutating func removeAllAssetsExceptions() {
		assetsExceptionList = []
	}

	mutating func removeAllAllowedDepositors() {
		depositorsAllowList = []
	}

	mutating func updateAssetsExceptionList(_ update: (inout AssetsExceptionList?) -> Void) {
		var identifiedExceptions = assetsExceptionList?.asIdentified()
		update(&identifiedExceptions)
		assetsExceptionList = identifiedExceptions?.elements
	}

	mutating func updateDepositorsAllowList(_ update: (inout DepositorsAllowList?) -> Void) {
		var identifiedExceptions = depositorsAllowList?.asIdentified()
		update(&identifiedExceptions)
		depositorsAllowList = identifiedExceptions?.elements
	}

	mutating func appendToDepositorsAllowList(_ new: ResourceOrNonFungible) {
		guard var identifiedAssetsExceptions = depositorsAllowList?.asIdentified() else {
			depositorsAllowList = [new]
			return
		}
		identifiedAssetsExceptions.updateOrAppend(new)
		depositorsAllowList = identifiedAssetsExceptions.elements
	}
}
