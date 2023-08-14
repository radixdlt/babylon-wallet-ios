import FeaturePrelude
import TransactionClient

extension AdvancedCustomizationFees.State {
	var viewState: AdvancedCustomizationFees.ViewState {
		.init(
		)
	}
}

extension AdvancedCustomizationFees {
	public struct ViewState: Equatable, Sendable {
		let feeViewStates: IdentifiedArrayOf<FeeViewState>

		let paddingAmountStr: String
		let tipPercentageStr: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AdvancedCustomizationFees>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					Group {
						Divider()
						AppTextField(
							primaryHeading: "Adjust Fee Padding Amount (XRD)", // TODO: strings
							placeholder: "",
							text: viewStore.binding(
								get: \.paddingAmountStr,
								send: ViewAction.paddingAmountChanged
							)
						)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.padding(.vertical, .medium1)

						AppTextField(
							primaryHeading: "Adjust Tip to Lock", // TODO: strings
							secondaryHeading: "(% of Execution + Finalization Fees)",
							placeholder: "",
							text: viewStore.binding(
								get: \.tipPercentageStr,
								send: ViewAction.tipPercentageChanged
							)
						)
						.keyboardType(.decimalPad)
						.multilineTextAlignment(.trailing)
						.padding(.bottom, .medium1)

						HStack {
							Text("Estimated transaction fees") // TODO: strings
								.textStyle(.body1Link)
								.foregroundColor(.app.gray2)
								.textCase(.uppercase)
							Spacer()
						}
						.padding(.bottom, .medium3)
					}
					.padding(.horizontal, .medium1)

					VStack(spacing: .small1) {
						ForEach(viewStore.feeViewStates) { viewState in
							feeView(state: viewState)
						}

						Divider()

						transactionFeeView(fee: viewStore.totalFee.format())
					}
					.padding(.medium1)
					.background(.app.gray5)
				}
			}
		}

		@ViewBuilder
		func transactionFeeView(fee: String) -> some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: .zero) {
					Text("Transaction Fee") // TODO: strings
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Text("(maximum to lock)") // TODO: strings
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
				}
				Spacer()
				Text(fee)
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)
			}
		}
	}
}
