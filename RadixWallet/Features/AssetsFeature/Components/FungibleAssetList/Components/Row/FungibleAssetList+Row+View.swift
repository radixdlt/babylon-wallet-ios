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

extension ResourceBalance.Fungible {
	init(resource: OnLedgerEntity.OwnedFungibleResource, isXRD: Bool) {
		self.init(
			address: resource.resourceAddress,
			icon: isXRD ? .xrd : .other(resource.metadata.iconURL),
			title: resource.metadata.title,
			amount: .init(resource.amount)
		)
	}
}

// MARK: - FungibleTokenList.Row.View
extension FungibleAssetList.Section.Row {
	public struct ViewState: Equatable {
		let resource: ResourceBalance.Fungible
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
				ResourceBalanceView(resource: .fungible(viewStore.resource), isSelected: viewStore.isSelected)
					.frame(height: 2 * .large1)
					.padding(.horizontal, .medium1)
					.contentShape(Rectangle())
					.onTapGesture { viewStore.send(.tapped) }
			}
		}
	}
}
