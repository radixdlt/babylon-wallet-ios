import FeaturePrelude
import TransactionClient

extension AdvancedCustomizationFees.State {
	var viewState: AdvancedCustomizationFees.ViewState {
		.init(
			paddingAmount: advancedCustomization.paddingFee,
			tipPercentage: advancedCustomization.tipPercentage,
			networkExecution: advancedCustomization.feeSummary.executionCost,
			networkFinalization: advancedCustomization.feeSummary.finalizationCost,
			effectiveTip: advancedCustomization.tipAmount,
			netowkrStorage: advancedCustomization.feeSummary.storageExpansionCost,
			royalties: advancedCustomization.feeSummary.royaltyCost,
			totalFee: advancedCustomization.total
		)
	}
}

extension AdvancedCustomizationFees {
	public struct ViewState: Equatable, Sendable {
		let paddingAmount: BigDecimal
		let tipPercentage: BigDecimal
		let networkExecution: BigDecimal
		let networkFinalization: BigDecimal
		let effectiveTip: BigDecimal
		let netowkrStorage: BigDecimal
		let royalties: BigDecimal
		let totalFee: BigDecimal

		var paddingAmountStr: String {
			paddingAmount.format()
		}

		var tipPercentageStr: String {
			tipPercentage.format()
		}
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
						.keyboardType(.numbersAndPunctuation)
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
						.keyboardType(.numbersAndPunctuation)
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
						feeView(title: "NETWORK EXECUTION", fee: viewStore.networkExecution) // TODO: strings
						feeView(title: "NETWORK FINALIZATION", fee: viewStore.networkFinalization) // TODO: strings
						feeView(title: "EFFECTIVE TIP", fee: viewStore.effectiveTip, showZero: true) // TODO: strings
						feeView(title: "NETWORK STORAGE", fee: viewStore.netowkrStorage) // TODO: strings
						feeView(title: "PADDING", fee: viewStore.paddingAmount, showZero: true) // TODO: strings
						feeView(title: "ROYALTIES", fee: viewStore.royalties) // TODO: strings

						Divider()

						transactionFeeView(fee: viewStore.totalFee.format())
					}
					.padding(.medium1)
					.background(.app.gray5)
				}
			}
		}

		@ViewBuilder
		func feeView(title: String, fee: BigDecimal, showZero: Bool = false) -> some SwiftUI.View {
			HStack {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				Spacer()
				Text(fee.formatted(showZero))
					.textStyle(.body1HighImportance)
					.foregroundColor(fee == .zero ? .app.gray2 : .app.gray1)
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
