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
		HStack {
			SwitchStore(store) { state in
				switch state {
				case .fungibleAsset:
					CaseLet(
						/ResourceAsset.State.fungibleAsset,
						action: { ResourceAsset.Action.child(.fungibleAsset($0)) },
						then: { FungibleResourceAsset.View(store: $0) }
					)

				case .nonFungibleAsset:
					CaseLet(
						/ResourceAsset.State.nonFungibleAsset,
						action: { ResourceAsset.Action.child(.nonFungibleAsset($0)) },
						then: { NonFungibleResourceAsset.View(store: $0) }
					)
				}
			}
			.background(.app.white)
			.focused($focused)
			.roundedCorners(strokeColor: focused ? .app.gray1 : .app.white)
			.tokenRowShadow()

			Spacer()

			Button {
				store.send(.view(.removeTapped))
			} label: {
				Image(asset: AssetResource.close)
					.frame(.smallest)
			}
			.foregroundColor(.app.gray2)
		}
	}
}
