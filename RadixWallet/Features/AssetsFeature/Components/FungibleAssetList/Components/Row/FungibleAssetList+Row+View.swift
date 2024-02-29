import ComposableArchitecture
import SwiftUI

extension FungibleAssetList.Section.Row.State {
	var viewState: FungibleAssetList.Section.Row.ViewState {
		.init(
			resource: .init(resource: token, isXRD: isXRD),
			isSelected: isSelected
		)
	}
}

extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.OwnedFungibleResource, isXRD: Bool) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: .init(resource.amount.nominalAmount, fiatWorth: resource.amount.fiatWorth)
		)
	}

	var withoutAmount: Self {
		.init(address: address, icon: icon, title: title, amount: nil)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleAssetList.Section.Row {
	public struct ViewState: Equatable {
		let resource: ResourceBalance.ViewState.Fungible
		let isSelected: Bool?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleAssetList.Section.Row>

		public init(store: StoreOf<FungibleAssetList.Section.Row>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: FeatureAction.view) { viewStore in
				ResourceBalanceButton(.fungible(viewStore.resource), appearance: .assetList, isSelected: viewStore.isSelected) {
					viewStore.send(.tapped)
				}
			}
		}
	}
}
