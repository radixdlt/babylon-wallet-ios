import FeaturePrelude

extension ResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ResourceAsset>
		@FocusState
		private var focused: Bool

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
				.background(.app.white)
				.focused($focused)
				.roundedCorners(strokeColor: focused ? .app.gray1 : .app.white)

				Spacer()
				Button("", asset: AssetResource.close) {
					viewStore.send(.removeTapped)
				}
				.foregroundColor(.app.gray2)
			}
			.padding(.small1)
		}
	}
}
