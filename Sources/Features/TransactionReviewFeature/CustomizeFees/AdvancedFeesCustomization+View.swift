import FeaturePrelude
import TransactionClient

extension AdvancedFeesCustomization.State {
	var viewState: AdvancedFeesCustomization.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total, isAdvancedMode: true),
			paddingAmountStr: paddingAmountStr,
			tipPercentageStr: tipPercentageStr,
			focusField: focusField
		)
	}
}

extension AdvancedFeesCustomization {
	public struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState

		let paddingAmountStr: String
		let tipPercentageStr: String
		let focusField: State.FocusField?
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AdvancedFeesCustomization>
		@FocusState
		var focusField: State.FocusField?

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationView {
					VStack(spacing: .zero) {
						Group {
							Divider()
							AppTextField(
								primaryHeading: "Adjust Fee Padding Amount (XRD)", // TODO: strings
								placeholder: "",
								text: viewStore.binding(
									get: \.paddingAmountStr,
									send: ViewAction.paddingAmountChanged
								),
								focus: .on(
									.padding,
									binding: viewStore.binding(
										get: \.focusField,
										send: { .focusChanged($0) }
									),
									to: $focusField
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
								),
								focus: .on(
									.tipPercentage,
									binding: viewStore.binding(
										get: \.focusField,
										send: { .focusChanged($0) }
									),
									to: $focusField
								)
							)
							.keyboardType(.decimalPad)
							.multilineTextAlignment(.trailing)
							.padding(.bottom, .medium1)
						}
						.padding(.horizontal, .medium1)

						FeesView(viewState: viewStore.feesViewState)
					}
					.toolbar {
						ToolbarItemGroup(placement: .keyboard) {
							Spacer()
							Button(L10n.Common.done) {
								viewStore.send(.focusChanged(nil))
							}
							.foregroundColor(.app.blue1)
						}
					}
				}
			}
		}
	}
}
