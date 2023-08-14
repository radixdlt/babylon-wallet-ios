import FeaturePrelude
import TransactionClient

extension NormalCustomizationFees.State {
	var viewState: NormalCustomizationFees.ViewState {
		.init(
			networkFee: normalCustomization.networkFee,
			royaltyFee: normalCustomization.royaltyFee,
			totalFee: normalCustomization.total.format()
		)
	}
}

extension NormalCustomizationFees {
	public struct ViewState: Equatable, Sendable {
		let networkFee: BigDecimal
		let royaltyFee: BigDecimal
		let totalFee: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<NormalCustomizationFees>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				VStack(spacing: .small1) {
					feeView(title: "Network Fees", fee: viewStore.networkFee) // TODO: strings
					feeView(title: "Royalty Fees", fee: viewStore.royaltyFee) // TODO: strings

					Divider()

					transactionFeeView(fee: viewStore.totalFee)
				}
				.padding(.medium1)
				.background(.app.gray5)
			}
		}

		@ViewBuilder
		func feeView(title: String, fee: BigDecimal) -> some SwiftUI.View {
			HStack {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				Spacer()
				Text(fee.formatted(false))
					.textStyle(.body1HighImportance)
					.foregroundColor(fee == .zero ? .app.gray2 : .app.gray1)
			}
		}

		@ViewBuilder
		func transactionFeeView(fee: String) -> some SwiftUI.View {
			HStack {
				Text("Transaction Fee") // TODO: strings
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				Spacer()
				Text(fee)
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)
			}
		}
	}
}
