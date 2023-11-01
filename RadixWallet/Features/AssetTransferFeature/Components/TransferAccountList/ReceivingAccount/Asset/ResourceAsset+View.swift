import ComposableArchitecture
import SwiftUI
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
		VStack(spacing: .small3) {
			HStack {
				SwitchStore(store.scope(state: \.kind, action: { .child($0) })) { state in
					switch state {
					case .fungibleAsset:
						CaseLet(
							/ResourceAsset.State.Kind.fungibleAsset,
							action: ResourceAsset.ChildAction.fungibleAsset,
							then: { FungibleResourceAsset.View(store: $0) }
						)

					case .nonFungibleAsset:
						CaseLet(
							/ResourceAsset.State.Kind.nonFungibleAsset,
							action: ResourceAsset.ChildAction.nonFungibleAsset,
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

			WithViewStore(store, observe: \.additionalSignatureRequired) { viewStore in
				if viewStore.state {
					WarningErrorView(text: "Additional signature required to deposit", type: .warning)
				}
			}
		}
	}
}
