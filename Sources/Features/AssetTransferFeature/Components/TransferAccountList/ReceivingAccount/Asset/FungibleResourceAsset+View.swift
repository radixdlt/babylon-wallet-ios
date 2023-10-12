import FeaturePrelude

extension FungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleResourceAsset>

		@FocusState
		private var focused: Bool

		public init(store: StoreOf<FungibleResourceAsset>) {
			self.store = store
		}
	}
}

extension ViewStore<FungibleResourceAsset.State, FungibleResourceAsset.ViewAction> {
	var focusedBinding: Binding<Bool> {
		binding(get: \.focused, send: ViewAction.focusChanged)
	}
}

extension FungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .trailing) {
				HStack {
					TokenThumbnail(viewStore.isXRD ? .xrd : .known(viewStore.resource.metadata.iconURL), size: .smallest)
					if let name = viewStore.resource.metadata.name {
						Text(name)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}

					TextField(
						"0.00",
						text: viewStore.binding(
							get: \.transferAmountStr,
							send: { .amountChanged($0) }
						)
					)
					.keyboardType(.decimalPad)
					.lineLimit(1)
					.multilineTextAlignment(.trailing)
					.foregroundColor(.app.gray1)
					.textStyle(.sectionHeader)
					.focused($focused)
					.bind(viewStore.focusedBinding, to: $focused)
				}

				if viewStore.totalExceedsBalance {
					// TODO: Add better style
					Text(L10n.AssetTransfer.FungibleResource.totalExceedsBalance)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.red1)
				}

				if focused {
					HStack {
						Button {
							viewStore.send(.maxAmountTapped)
						} label: {
							Text(L10n.Common.max)
								.underline()
								.textStyle(.body3HighImportance)
								.foregroundColor(.app.blue2)
						}

						Group {
							Text("-")
							Text(L10n.AssetTransfer.FungibleResource.balance(viewStore.balance.formatted()))
						}
						.textStyle(.body3HighImportance)
						.foregroundColor(.app.gray2)
					}
				}
			}
			.padding(.medium3)
		}
	}
}
