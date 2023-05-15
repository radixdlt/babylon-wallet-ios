import FeaturePrelude

// MARK: - ToAccountTransfer.View
extension ToAccountTransfer {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ToAccountTransfer>
		let focused: FocusState<FocusField?>.Binding

		public init(store: StoreOf<ToAccountTransfer>, focused: FocusState<FocusField?>.Binding) {
			self.store = store
			self.focused = focused
		}
	}
}

extension ToAccountTransfer.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading, spacing: 0) {
				HStack {
					Button("Choose Account") {
						viewStore.send(.chooseAccountTapped)
					}.textStyle(.body1Header)
					Spacer()
					Button("", asset: AssetResource.close) {
						viewStore.send(.removeTapped)
					}
				}
				.foregroundColor(.app.gray2)
				.padding(.medium3)
				.topRoundedCorners(strokeColor: .app.gray4)

				VStack {
					HStack {
						Spacer()
						Button("Add Assets") {
							viewStore.send(.addAssetTapped)
						}
						.padding(.medium1)
						.textStyle(.body1Header)
						Spacer()
					}
				}
				.foregroundColor(.app.gray2)
				.background(.app.gray5)
				.bottomRoundedCorners(strokeColor: .app.gray4)
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /ToAccountTransfer.Destinations.State.chooseAccount,
				action: ToAccountTransfer.Destinations.Action.chooseAccount,
				content: { ChooseAccount.View(store: $0) }
			)
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /ToAccountTransfer.Destinations.State.addAsset,
				action: ToAccountTransfer.Destinations.Action.addAsset,
				content: { AddAsset.View(store: $0) }
			)
		}
	}
}
