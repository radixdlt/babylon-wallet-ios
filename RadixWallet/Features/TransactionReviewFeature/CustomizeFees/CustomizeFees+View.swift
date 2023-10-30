
extension CustomizeFees.State {
	// Need to disable, since broken in swiftformat 0.52.7
	// swiftformat:disable redundantClosure

	var viewState: CustomizeFees.ViewState {
		.init(
			title: {
				switch transactionFee.mode {
				case .normal:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.NormalMode.title
				case .advanced:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.AdvancedMode.title
				}
			}(),
			description: {
				switch transactionFee.mode {
				case .normal:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.NormalMode.subtitle
				case .advanced:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.AdvancedMode.subtitle
				}
			}(),
			modeSwitchTitle: {
				switch transactionFee.mode {
				case .normal:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.viewAdvancedModeButtonTitle
				case .advanced:
					L10n.TransactionReview.CustomizeNetworkFeeSheet.viewNormalModeButtonTitle
				}
			}(),
			feePayer: feePayerSelection.selected,
			noFeePayerText: {
				if transactionFee.totalFee.lockFee == .zero {
					L10n.TransactionReview.CustomizeNetworkFeeSheet.noneRequired
				} else {
					L10n.TransactionReview.CustomizeNetworkFeeSheet.noAccountSelected
				}
			}(),
			insufficientBalanceMessage: {
				if let feePayer = feePayerSelection.selected {
					if feePayer.xrdBalance < transactionFee.totalFee.lockFee {
						return L10n.TransactionReview.CustomizeNetworkFeeSheet.InsufficientBalance.warning
					}
				}
				return nil
			}()
		)
	}

	// swiftformat:enable redundantClosure
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
							viewStore.send(.closeButtonTapped)
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
										/CustomizeFees.State.CustomizationModeState.normal,
										action: CustomizeFees.ChildAction.normalFeesCustomization,
										then: {
											NormalFeesCustomization.View(store: $0)
										}
									)
								case .advanced:
									CaseLet(
										/CustomizeFees.State.CustomizationModeState.advanced,
										action: CustomizeFees.ChildAction.advancedFeesCustomization,
										then: {
											AdvancedFeesCustomization.View(store: $0)
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
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /CustomizeFees.Destinations.State.selectFeePayer,
				action: CustomizeFees.Destinations.Action.selectFeePayer,
				content: { SelectFeePayer.View(store: $0) }
			)
		}

		@ViewBuilder
		func infoView(_ viewStore: ViewStoreOf<CustomizeFees>) -> some SwiftUI.View {
			VStack {
				Text(viewStore.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .small1)
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
					Text(L10n.TransactionReview.CustomizeNetworkFeeSheet.payFeeFrom)
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)

					Spacer()
					Button(L10n.TransactionReview.CustomizeNetworkFeeSheet.changeButtonTitle) {
						viewStore.send(.changeFeePayerTapped)
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
				if let feePayer = viewStore.feePayer?.account {
					SmallAccountCard(
						feePayer.displayName.rawValue,
						identifiable: .address(of: feePayer),
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
	}
}
