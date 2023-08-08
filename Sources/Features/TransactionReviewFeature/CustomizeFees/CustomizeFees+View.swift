import FeaturePrelude
import TransactionClient

extension CustomizeFees.State {
	var viewState: CustomizeFees.ViewState {
		// TODO: strings
		.init(
			title: transactionFee.mode == .normal ? "Customize Fees" : "Advanced \n Customize Fees",
			description: transactionFee.mode == .normal ? "Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary." : "Fully customize fee payment for this transaction. Not recommended unless you are a developer or advanced user.",
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
						return "Insufficient balance to pay the transaction fee"
					}
				}
				return nil
			}()
		)
	}
}

extension CustomizeFees {
	public struct ViewState: Equatable {
		let title: String
		let description: String
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
				VStack(spacing: .zero) {
					HStack {
						CloseButton {
							viewStore.send(.closed)
						}
						Spacer()
					}
					ScrollView {
						VStack(spacing: .zero) {
							VStack {
								infoView(viewStore)
								Divider()

								feePayerView(viewStore)
									.padding(.top, .small1)
							}
							.padding([.horizontal, .bottom], .medium1)

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
						.padding(.bottom, .medium1)
					}
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

		func infoView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack {
				Text(viewStore.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.padding(.bottom, .small1)
					.multilineTextAlignment(.center)
				Text(viewStore.description)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium2)
			}
		}

		@ViewBuilder
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
				Divider()

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

private extension BigDecimal {
	func formatted(_ showsZero: Bool) -> String {
		if !showsZero, self == .zero {
			return "None Due" // TODO: strings
		}
		return "\(format()) XRD"
	}
}
