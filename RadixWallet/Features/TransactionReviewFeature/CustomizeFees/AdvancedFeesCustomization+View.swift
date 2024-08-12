import ComposableArchitecture
import SwiftUI

extension AdvancedFeesCustomization.State {
	var feesViewState: FeesView.ViewState {
		.init(feeViewStates: fees.viewStates, totalFee: fees.total, isAdvancedMode: true)
	}

	var paddingAmountHint: Hint.ViewState? {
		guard parsedPaddingFee == nil else { return nil }
		return .iconError()
	}

	var tipPercentageHint: Hint.ViewState? {
		guard parsedTipPercentage == nil else { return nil }
		return .iconError()
	}
}

// MARK: - AdvancedFeesCustomization.View
extension AdvancedFeesCustomization {
	@MainActor
	public struct View: SwiftUI.View {
		@Perception.Bindable
		var store: StoreOf<AdvancedFeesCustomization>
		@FocusState
		var focusField: State.FocusField?

		var paddingAmount: Binding<String> {
			$store.paddingAmount.sending(\.view.paddingAmountChanged)
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					Group {
						Divider()

						AppTextField(
							primaryHeading: .init(text: L10n.CustomizeNetworkFees.paddingFieldLabel),
							placeholder: "",
							text: $store.paddingAmount.sending(\.view.paddingAmountChanged),
							hint: store.paddingAmountHint,
							focus: .on(
								.padding,
								binding: $store.focusField.sending(\.view.focusChanged),
								to: $focusField
							)
						)
						.keyboardType(.decimalPad)
						.padding(.vertical, .medium1)

						AppTextField(
							primaryHeading: .init(text: L10n.CustomizeNetworkFees.tipFieldLabel),
							subHeading: L10n.CustomizeNetworkFees.tipFieldInfo,
							placeholder: "",
							text: $store.tipPercentage.sending(\.view.tipPercentageChanged),
							hint: store.tipPercentageHint,
							focus: .on(
								.tipPercentage,
								binding: $store.focusField.sending(\.view.focusChanged),
								to: $focusField
							)
						)
						.keyboardType(.numberPad)
						.padding(.bottom, .medium1)
					}
					.multilineTextAlignment(.trailing)
					.padding(.horizontal, .medium1)

					FeesView(viewState: store.feesViewState)
				}
				.toolbar {
					ToolbarItemGroup(placement: .keyboard) {
						Spacer()
						Button(L10n.Common.done) {
							store.send(.view(.focusChanged(nil)))
						}
						.foregroundColor(.app.blue1)
					}
				}
			}
		}
	}
}
