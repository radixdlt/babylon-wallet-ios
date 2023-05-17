import FeaturePrelude

extension ResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ResourceAsset>
		public init(store: StoreOf<ResourceAsset>) {
			self.store = store
		}
	}
}

extension ResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			HStack {
				SwitchStore(store) {
					CaseLet(
						state: /ResourceAsset.State.fungibleAsset,
						action: { ResourceAsset.Action.child(.fungibleAsset($0)) },
						then: { FungibleResourceAsset.View(store: $0) }
					)

					CaseLet(
						state: /ResourceAsset.State.nonFungibleAsset,
						action: { ResourceAsset.Action.child(.nonFungibleAsset($0)) },
						then: { NonFungibleResourceAsset.View(store: $0.actionless) }
					)
				}
				Spacer()
				Button("", asset: AssetResource.close) {
					viewStore.send(.removeTapped)
				}
			}
		}
	}
}
