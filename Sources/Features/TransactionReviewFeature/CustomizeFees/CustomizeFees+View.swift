import FeaturePrelude
import TransactionClient

extension CustomizeFees.State {
	var viewState: CustomizeFees.ViewState {
		.init(
			isNormalMode: transactionFee.mode == .normal,
			totalNetworkAndRoyaltyFee: {
				if case let .advanced(advanced) = transactionFee.mode {
					return advanced.networkAndRoyaltyFee.format()
				}
				return ""
			}(),
			tipPercentage: {
				if case let .advanced(advanced) = transactionFee.mode {
					return advanced.tipPercentage.format()
				}
				return ""
			}(),
			modeSwitchTitle: {
				switch transactionFee.mode {
				case .normal:
					return "View Advanced Mode" // TODO: strings
				case .advanced:
					return "View Normal Mode" // TODO: strings
				}
			}(),
			feePayer: feePayerSelection.selected,
			noFeePayerText: {
				if transactionFee.totalFee.lockFee == .zero {
					return "None required" // TODO: strings
				} else {
					return "No Account selected" // TODO: strings
				}
			}(),
			networkFee: transactionFee.networkFee,
			royaltyFee: transactionFee.royaltyFee,
			totalFee: transactionFee.totalFee.displayedTotalFee,
			insufficientBalanceMessage: {
				if let feePayer = feePayerSelection.selected {
					if feePayer.xrdBalance < transactionFee.totalFee.lockFee {
						return "Insufficient balance to pay the transaction fee, please choose another account" // TODO: strings
					}
				}
				return nil
			}()
		)
	}
}

extension CustomizeFees {
	public struct ViewState: Equatable {
		let isNormalMode: Bool
		let totalNetworkAndRoyaltyFee: String
		let tipPercentage: String
		let modeSwitchTitle: String
		let feePayer: FeePayerCandidate?
		let noFeePayerText: String
		let networkFee: BigDecimal
		let royaltyFee: BigDecimal
		let totalFee: String
		let insufficientBalanceMessage: String?
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<CustomizeFees>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack {
						VStack {
							Text("Customize Fees") // TODO: strings
								.textStyle(.sheetTitle)
								.foregroundColor(.app.gray1)
								.padding(.bottom, .small1)
							Text("Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary.") // TODO: strings
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)
								.multilineTextAlignment(.center)
								.padding(.bottom, .medium2)
							Divider()

							feePayerView(viewStore)
								.padding(.top, .small1)
						}
						.padding(.medium1)

						if viewStore.isNormalMode {
							normalModeFeesBreakdownView(viewStore)
						} else {
							advancedModeBreakdownView(viewStore)
						}
					}
					.padding(.vertical, .medium3)

					Button(viewStore.modeSwitchTitle) {
						viewStore.send(.toggleMode)
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
				.background(.app.background)
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /CustomizeFees.Destinations.State.selectFeePayer,
				action: CustomizeFees.Destinations.Action.selectFeePayer,
				content: { SelectFeePayer.View(store: $0) }
			)
		}

		func feePayerView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack(alignment: .leading) {
				HStack {
					Text("Pay Fee From") // TODO: strings
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)

					Spacer()
					Button("Change") { // TODO: strings
						viewStore.send(.changeFeePayerTapped)
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
				if let feePayer = viewStore.feePayer?.account {
					SmallAccountCard(
						feePayer.displayName.rawValue,
						identifiable: .address(.account(feePayer.address)),
						gradient: .init(feePayer.appearanceID)
					)
					.cornerRadius(.small1)
				} else {
					AppTextField(
						placeholder: "",
						text: .constant(viewStore.noFeePayerText)
					)
					.disabled(true)
				}

				if let insufficientBalanceMessage = viewStore.insufficientBalanceMessage {
					WarningErrorView(text: insufficientBalanceMessage, type: .error)
				}
			}
		}

		@ViewBuilder
		func advancedModeBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				AppTextField(
					primaryHeading: "XRD to Lock for Network & Royalty Fees", // TODO: strings
					placeholder: "",
					text: viewStore.binding(
						get: \.totalNetworkAndRoyaltyFee,
						send: ViewAction.totalNetworkAndRoyaltyFeesChanged
					)
				)

				AppTextField(
					primaryHeading: "Tip to Lock (% of Network Fee)", // TODO: strings
					placeholder: "",
					text: viewStore.binding(
						get: \.tipPercentage,
						send: ViewAction.tipPercentageChanged
					)
				)
				.keyboardType(.decimalPad)

				transactionFeeView(fee: viewStore.totalFee)
			}
			.multilineTextAlignment(.trailing)
			.padding(.horizontal, .medium1)
		}

		@ViewBuilder
		func normalModeFeesBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				normalModeFeeView(title: "Network Fees", fee: viewStore.networkFee) // TODO: strings
				normalModeFeeView(title: "Royalty Fees", fee: viewStore.royaltyFee) // TODO: strings

				Divider()

				transactionFeeView(fee: viewStore.totalFee)
			}
			.padding(.medium1)
			.background(.app.gray5)
		}

		@ViewBuilder
		func normalModeFeeView(title: String, fee: BigDecimal) -> some SwiftUI.View {
			HStack {
				Text(title)
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.textCase(.uppercase)
				Spacer()
				Text(fee.formatted(false))
					.textStyle(.body1HighImportance)
					.foregroundColor(fee == .zero ? .app.gray3 : .app.gray1)
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

private extension BigDecimal {
	func formatted(_ showsZero: Bool) -> String {
		if !showsZero, self == .zero {
			return "None Due" // TODO: strings
		}
		return "\(format()) XRD"
	}
}
