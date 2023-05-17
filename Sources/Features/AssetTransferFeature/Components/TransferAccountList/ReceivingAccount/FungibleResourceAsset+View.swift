import FeaturePrelude

extension FungibleResourceAsset {
	public typealias ViewState = State

	enum Focus {
		case entry
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleResourceAsset>
		let focused: FocusState<TransferFocusedField?>.Binding
		@FocusState
		var textFieldIsFocused: Bool

		@FocusState
		var isFocused: Focus?

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
				VStack(alignment: .trailing) {
					HStack {
						Image(asset: AssetResource.xrd)
							.resizable()
							.frame(.smallest)
						Text("XRD")
							.foregroundColor(.app.gray1)
							.textStyle(.body2HighImportance)

						TextField("0.00",
						          text: viewStore.binding(
						          	get: \.amount,
						          	send: { .amountChanged($0) }
						          ))
						          .keyboardType(.decimalPad)
						          .lineLimit(1)
						          .multilineTextAlignment(.trailing)
						          .foregroundColor(.app.gray1)
						          .textStyle(.sectionHeader)
						          .focused($isFocused, equals: .entry)
					}

					if isFocused == .entry {
						// TODO: beutify
						HStack {
							Button("Max") {
								viewStore.send(.maxAmountTapped)
							}
							Text("-")
                                                        Text("Balance \(viewStore.balance.format())")
						}
					}
				}
				.padding(.medium3)
				.background(.app.white)
				.roundedCorners(strokeColor: isFocused != nil ? .app.gray1 : .app.white, corners: .allCorners)

				Spacer()
				Button("", asset: AssetResource.close) {
					viewStore.send(.removeTapped)
				}
			}
			.padding(.small1)
		}
	}
}
