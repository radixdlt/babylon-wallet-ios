import FeaturePrelude

extension FungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleResourceAsset>
		let focused: FocusState<TransferFocusedField?>.Binding

		public init(store: StoreOf<FungibleResourceAsset>, focused: FocusState<TransferFocusedField?>.Binding) {
			self.store = store
			self.focused = focused
		}
	}
}

extension FungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			HStack {
				HStack {
					Image(asset: AssetResource.xrd)
						.resizable()
						.frame(.smallest)
					Text("XRD")
						.foregroundColor(.app.gray1)
						.textStyle(.body2HighImportance)

					Spacer()

					TextField("0.00", text: viewStore.binding(get: \.amount, send: { .amountChanged($0) }))
						.keyboardType(.numbersAndPunctuation)
						.lineLimit(1)
						.multilineTextAlignment(.trailing)
						.foregroundColor(.app.gray1)
						.textStyle(.sectionHeader)
					// .focused(focused, equals: .asset(accountContainer: <#T##ReceivingAccount.State.ID#>, asset: <#T##UUID#>))
				}
				.padding(.medium3)
				.background(.app.white)
				.cornerRadius(.small2)

				Spacer()
				Button("", asset: AssetResource.close) {
					// viewStore.send(.)
				}
			}
			.padding(.small1)
		}
	}
}
