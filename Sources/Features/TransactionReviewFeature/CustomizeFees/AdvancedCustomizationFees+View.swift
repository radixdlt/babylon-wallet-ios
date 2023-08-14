import FeaturePrelude
import TransactionClient

extension AdvancedCustomizationFees.State {
	var viewState: AdvancedCustomizationFees.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total),
			paddingAmountStr: fees.paddingFee.format(),
			tipPercentageStr: fees.tipPercentage.format()
		)
	}
}

extension AdvancedCustomizationFees {
	public struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState

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
					}
					.padding(.horizontal, .medium1)

					FeesView(viewState: viewStore.feesViewState)
				}
			}
		}
	}
}
