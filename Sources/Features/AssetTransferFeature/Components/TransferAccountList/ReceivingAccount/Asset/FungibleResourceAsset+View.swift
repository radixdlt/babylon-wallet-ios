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
						TokenThumbnail(.xrd, size: .smallest)

						if let name = viewStore.resource.name {
							Text(name)
								.textStyle(.body2HighImportance)
								.foregroundColor(.app.gray1)
						}

						TextField("0.00",
						          text: viewStore.binding(
						          	get: \.transferAmountStr,
						          	send: { .amountChanged($0) }
						          ))
						          .keyboardType(.decimalPad)
						          .lineLimit(1)
						          .multilineTextAlignment(.trailing)
						          .foregroundColor(.app.gray1)
						          .textStyle(.sectionHeader)
						          .focused($focused)
					}

					if viewStore.totalTransferSum > viewStore.balance {
						// TODO: Add better style
						Text("Total Sum is over your current balance")
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.red1)
					}

					if focused {
						// TODO: beutify
						HStack {
							Button {
								viewStore.send(.maxAmountTapped)
							} label: {
								Text("Max")
									.underline()
									.textStyle(.body3HighImportance)
									.foregroundColor(.app.blue2)
							}

							Text("-")
							Text("Balance: \(viewStore.balance.format())")
								.textStyle(.body3HighImportance)
								.foregroundColor(.app.gray2)
						}
					}
				}
				.padding(.medium3)
			}
		}
	}
}
