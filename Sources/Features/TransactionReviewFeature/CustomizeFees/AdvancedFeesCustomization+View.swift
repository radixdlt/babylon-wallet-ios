import FeaturePrelude
import TransactionClient

extension AdvancedFeesCustomization.State {
	var viewState: AdvancedFeesCustomization.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total, isAdvancedMode: true),
			paddingAmount: paddingAmount,
			tipPercentage: tipPercentage,
			focusField: focusField
		)
	}
}

extension AdvancedFeesCustomization {
	public struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState

		let paddingAmount: String
		let tipPercentage: String
		let focusField: State.FocusField?
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AdvancedFeesCustomization>
		@FocusState
		var focusField: State.FocusField?

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					Group {
						Divider()
						AppTextField(
							primaryHeading: .init(text: L10n.TransactionReview.CustomizeNetworkFeeSheet.paddingFieldLabel),
							placeholder: "",
							text: viewStore.binding(
								get: \.paddingAmount,
								send: ViewAction.paddingAmountChanged
							),
							focus: .on(
								.padding,
								binding: viewStore.binding(
									get: \.focusField,
									send: ViewAction.focusChanged
								),
								to: $focusField
							)
						)
						.padding(.vertical, .medium1)

						AppTextField(
							primaryHeading: .init(text: L10n.TransactionReview.CustomizeNetworkFeeSheet.tipFieldLabel),
							subHeading: L10n.TransactionReview.CustomizeNetworkFeeSheet.tipFieldInfo,
							placeholder: "",
							text: viewStore.binding(
								get: \.tipPercentage,
								send: ViewAction.tipPercentageChanged
							),
							focus: .on(
								.tipPercentage,
								binding: viewStore.binding(
									get: \.focusField,
									send: ViewAction.focusChanged
								),
								to: $focusField
							)
						)
						.padding(.bottom, .medium1)
					}
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
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
