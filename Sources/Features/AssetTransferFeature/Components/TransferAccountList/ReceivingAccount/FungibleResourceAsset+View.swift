import FeaturePrelude

extension FungibleResourceAsset {
	public typealias ViewState = State

	enum Focus {
		case entry
	}

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
						          	get: \.amountStr,
						          	send: { .amountChanged($0) }
						          ))
						          .keyboardType(.decimalPad)
						          .lineLimit(1)
						          .multilineTextAlignment(.trailing)
						          .foregroundColor(.app.gray1)
						          .textStyle(.sectionHeader)
					}

					if viewStore.totalSum > viewStore.balance {
						// TODO: Add better style
						Text("Total Sum is over your current balance")
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.red1)
					}

					if focused {
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
				.roundedCorners(strokeColor: focused ? .app.gray1 : .app.white)

				Spacer()
				Button("", asset: AssetResource.close) {
					viewStore.send(.removeTapped)
				}
			}
			.padding(.small1)
			.focused($focused)
		}
	}
}
