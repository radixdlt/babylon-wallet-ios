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
					return "View Advanced Mode"
				case .advanced:
					return "View Normal Mode"
				}
			}(),
			feePayer: feePayerSelection.selected,
			noFeePayerText: {
				if transactionFee.totalFee.lockFee == .zero {
					return "None required"
				} else {
					return "No Account selected"
				}
			}(),
			networkFee: transactionFee.networkFee,
			royaltyFee: transactionFee.royaltyFee,
			totalFee: transactionFee.totalFee.displayedTotalFee,
			insufficientBalanceMessage: {
				if let feePayer = feePayerSelection.selected {
					if feePayer.xrdBalance < transactionFee.totalFee.lockFee {
						return "Insufficient balance to pay the transaction fee, please choose another account"
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
							Text("Customize Fees")
								.textStyle(.sheetTitle)
								.foregroundColor(.app.gray1)
								.padding(.bottom, .small1)
							Text("Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary.")
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
							feesBreakdownView(viewStore)
								.padding(.medium1)
								.background(.app.gray5)
						} else {
							VStack(spacing: .medium1) {
								AppTextField(
									primaryHeading: "XRD to Lock for Network & Royalty Fees",
									placeholder: "",
									text: viewStore.binding(
										get: \.totalNetworkAndRoyaltyFee,
										send: ViewAction.totalNetworkAndRoyaltyFeesChanged
									)
								)

								AppTextField(
									primaryHeading: "Tip to Lock (% of Network Fee)",
									placeholder: "",
									text: viewStore.binding(
										get: \.tipPercentage,
										send: ViewAction.tipPercentageChanged
									)
								)
								.keyboardType(.decimalPad)

								HStack {
									Text("Transaction Fee")
										.textStyle(.body1Link)
										.foregroundColor(.app.gray2)
										.textCase(.uppercase)
									Spacer()
									Text(viewStore.totalFee)
										.textStyle(.body1Header)
										.foregroundColor(.app.gray1)
								}
							}
							.multilineTextAlignment(.trailing)
							.padding(.horizontal, .medium1)
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
					Text("Pay Fee From")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)

					Spacer()
					Button("Change") {
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
					AppTextField(placeholder: "", text: .constant(viewStore.noFeePayerText))
						.disabled(true)
//					Text(viewStore.noFeePayerText)
//						.foregroundColor(.app.gray2)
//						.textStyle(.body1Header)
//						.background(.app.gray5)
				}

				if let insufficientBalanceMessage = viewStore.insufficientBalanceMessage {
					WarningErrorView(text: "Insufficient balance to pay the transaction fee", type: .error)
				}
			}
		}

		func feesBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				HStack {
					Text("Network Fee")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Spacer()
					Text(viewStore.networkFee.formatted(false))
						.textStyle(.body1HighImportance)
						.foregroundColor(viewStore.networkFee == .zero ? .app.gray3 : .app.gray1)
				}

				HStack {
					Text("Royalty Fees")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Spacer()
					Text(viewStore.royaltyFee.formatted(false))
						.textStyle(.body1HighImportance)
						.foregroundColor(viewStore.royaltyFee == .zero ? .app.gray3 : .app.gray1)
				}

				Divider()
				HStack {
					Text("Transaction Fee")
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Spacer()
					Text(viewStore.totalFee)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)
				}
			}
		}
	}
}

private extension BigDecimal {
	func formatted(_ showsZero: Bool) -> String {
		if !showsZero, self == .zero {
			return "None Due"
		}
		return "\(format()) XRD"
	}
}
