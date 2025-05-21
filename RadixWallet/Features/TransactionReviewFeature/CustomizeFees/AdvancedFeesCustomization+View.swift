import ComposableArchitecture
import SwiftUI

extension AdvancedFeesCustomization.State {
	var viewState: AdvancedFeesCustomization.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total, isAdvancedMode: true),
			paddingAmount: paddingAmount,
			paddingAmountHint: paddingAmountHint,
			tipPercentage: tipPercentage,
			tipPercentageHint: tipPercentageHint,
			focusField: focusField
		)
	}

	private var paddingAmountHint: Hint.ViewState? {
		guard parsedPaddingFee == nil else { return nil }
		return .iconError()
	}

	private var tipPercentageHint: Hint.ViewState? {
		guard parsedTipPercentage == nil else { return nil }
		return .iconError()
	}
}

extension AdvancedFeesCustomization {
	struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState

		let paddingAmount: String
		let paddingAmountHint: Hint.ViewState?
		let tipPercentage: String
		let tipPercentageHint: Hint.ViewState?
		let focusField: State.FocusField?
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<AdvancedFeesCustomization>
		@FocusState
		var focusField: State.FocusField?

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					Group {
						Separator()
						AppTextField(
							primaryHeading: .init(text: L10n.CustomizeNetworkFees.paddingFieldLabel),
							placeholder: "",
							text: viewStore.binding(
								get: \.paddingAmount,
								send: ViewAction.paddingAmountChanged
							),
							hint: viewStore.paddingAmountHint,
							focus: .on(
								.padding,
								binding: viewStore.binding(
									get: \.focusField,
									send: ViewAction.focusChanged
								),
								to: $focusField
							)
						)
						.keyboardType(.decimalPad)
						.padding(.vertical, .medium1)

						AppTextField(
							primaryHeading: .init(text: L10n.CustomizeNetworkFees.tipFieldLabel),
							subHeading: L10n.CustomizeNetworkFees.tipFieldInfo,
							placeholder: "",
							text: viewStore.binding(
								get: \.tipPercentage,
								send: ViewAction.tipPercentageChanged
							),
							hint: viewStore.tipPercentageHint,
							focus: .on(
								.tipPercentage,
								binding: viewStore.binding(
									get: \.focusField,
									send: ViewAction.focusChanged
								),
								to: $focusField
							)
						)
						.keyboardType(.numberPad)
						.padding(.bottom, .medium1)
					}
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
						.foregroundColor(.button)
					}
				}
			}
		}
	}
}
