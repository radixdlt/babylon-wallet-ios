import FeaturePrelude
import TransactionClient

extension CustomizeFees.State {
	var viewState: CustomizeFees.ViewState {
		// TODO: strings
		.init(
			title: {
				switch transactionFee.mode {
				case .normal:
					return "Customize Fees"
				case .advanced:
					return "Advanced \n Customize Fees"
				}
			}(),
			description: {
				switch transactionFee.mode {
				case .normal:
					return "Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary."
				case .advanced:
					return "Fully customize fee payment for this transaction. Not recommended unless you are a developer or advanced user."
				}
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
		let modeSwitchTitle: String
		let feePayer: FeePayerCandidate?
		let noFeePayerText: String
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

							SwitchStore(store.scope(state: \.modeState, action: Action.child)) { state in
								switch state {
								case .normal:
									CaseLet(
										state: /CustomizeFees.State.CustomizationModeState.normal,
										action: CustomizeFees.ChildAction.normalFeeCustomization,
										then: {
											NormalCustomizationFees.View(store: $0)
										}
									)
								case .advanced:
									CaseLet(
										state: /CustomizeFees.State.CustomizationModeState.advanced,
										action: CustomizeFees.ChildAction.advancedFeeCustomization,
										then: {
											AdvancedCustomizationFees.View(store: $0)
										}
									)
								}
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

//		@ViewBuilder
//		func advancedModeBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
//			VStack(spacing: .medium1) {
//				Divider()
//
//				AppTextField(
//					primaryHeading: "Adjust Fee Padding Amount (XRD)", // TODO: strings
//					placeholder: "",
//					text: viewStore.binding(
//						get: \.totalNetworkAndRoyaltyFee,
//						send: ViewAction.totalNetworkAndRoyaltyFeesChanged
//					)
//				)
		//                                .keyboardType(.numbersAndPunctuation)
//
//				AppTextField(
//					primaryHeading: "Adjust Tip to Lock", // TODO: strings
		//                                        secondaryHeading: "(% of Execution + Finalization Fees)",
//					placeholder: "",
//					text: viewStore.binding(
//						get: \.tipPercentage,
//						send: ViewAction.tipPercentageChanged
//					)
//				)
//				.keyboardType(.numbersAndPunctuation)
//
//				transactionFeeView(fee: viewStore.totalFee)
//			}
//			.multilineTextAlignment(.trailing)
//			.padding(.horizontal, .medium1)
//		}
//
//		@ViewBuilder
//		func normalModeFeesBreakdownView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
//			VStack(spacing: .small1) {
		//                                feeView(title: "Network Fees", fee: viewStore.networkFee) // TODO: strings
		//                                feeView(title: "Royalty Fees", fee: viewStore.royaltyFee) // TODO: strings
//
//				Divider()
//
//				transactionFeeView(fee: viewStore.totalFee)
//			}
//			.padding(.medium1)
//			.background(.app.gray5)
//		}
//
//		@ViewBuilder
//		func feeView(title: String, fee: BigDecimal) -> some SwiftUI.View {
//			HStack {
//				Text(title)
//					.textStyle(.body1Link)
//					.foregroundColor(.app.gray2)
//					.textCase(.uppercase)
//				Spacer()
//				Text(fee.formatted(false))
//					.textStyle(.body1HighImportance)
//					.foregroundColor(fee == .zero ? .app.gray2 : .app.gray1)
//			}
//		}
//
//		@ViewBuilder
//		func transactionFeeView(fee: String) -> some SwiftUI.View {
//			HStack {
//				Text("Transaction Fee") // TODO: strings
//					.textStyle(.body1Link)
//					.foregroundColor(.app.gray2)
//					.textCase(.uppercase)
//				Spacer()
//				Text(fee)
//					.textStyle(.body1Header)
//					.foregroundColor(.app.gray1)
//			}
//		}
	}
}

extension BigDecimal {
	func formatted(_ showsZero: Bool) -> String {
		if !showsZero, self == .zero {
			return "None Due" // TODO: strings
		}
		return "\(format()) XRD"
	}
}
