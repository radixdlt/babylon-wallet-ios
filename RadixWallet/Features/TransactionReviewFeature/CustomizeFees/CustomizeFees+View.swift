
extension CustomizeFees.State {
	var viewState: CustomizeFees.ViewState {
		.init(
			mode: transactionFee.mode,
			feePayer: feePayer?.account,
			feePayingValidation: feePayingValidation
		)
	}
}

extension CustomizeFees.ViewState {
	var title: String {
		switch mode {
		case .normal:
			L10n.CustomizeNetworkFees.NormalMode.title
		case .advanced:
			L10n.CustomizeNetworkFees.AdvancedMode.title
		}
	}

	var description: String {
		switch mode {
		case .normal:
			L10n.CustomizeNetworkFees.NormalMode.subtitle
		case .advanced:
			L10n.CustomizeNetworkFees.AdvancedMode.subtitle
		}
	}

	var modeSwitchTitle: String {
		switch mode {
		case .normal:
			L10n.CustomizeNetworkFees.viewAdvancedModeButtonTitle
		case .advanced:
			L10n.CustomizeNetworkFees.viewNormalModeButtonTitle
		}
	}

	var noFeePayerText: String {
		if feePayingValidation == .valid(.feePayerSuperfluous) {
			L10n.CustomizeNetworkFees.noneRequired
		} else {
			L10n.CustomizeNetworkFees.noAccountSelected
		}
	}

	var insufficientBalance: Bool {
		feePayingValidation == .insufficientBalance
	}

	var linkingNewAccount: Bool {
		feePayingValidation == .valid(.introducesNewAccount)
	}
}

extension CustomizeFees {
	struct ViewState: Equatable {
		let mode: TransactionFee.Mode
		let feePayer: Account?
		let feePayingValidation: FeePayerValidationOutcome?
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<CustomizeFees>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					ScrollView {
						VStack(spacing: .zero) {
							VStack {
								infoView(viewStore.state)
								Divider()
								feePayerView(viewStore.state)
									.padding(.top, .small1)
							}
							.padding([.horizontal, .bottom], .medium1)

							SwitchStore(store.scope(state: \.modeState, action: Action.child)) { state in
								switch state {
								case .normal:
									CaseLet(
										/CustomizeFees.State.CustomizationModeState.normal,
										action: CustomizeFees.ChildAction.normalFeesCustomization,
										then: { NormalFeesCustomization.View(store: $0) }
									)
								case .advanced:
									CaseLet(
										/CustomizeFees.State.CustomizationModeState.advanced,
										action: CustomizeFees.ChildAction.advancedFeesCustomization,
										then: { AdvancedFeesCustomization.View(store: $0) }
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
				.withNavigationBar {
					store.send(.view(.closeButtonTapped))
				}
			}
			.destinations(with: store)
		}

		@ViewBuilder
		func infoView(_ viewState: CustomizeFees.ViewState) -> some SwiftUI.View {
			VStack {
				Text(viewState.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.primaryText)
					.multilineTextAlignment(.center)
					.padding(.bottom, .small1)
				Text(viewState.description)
					.textStyle(.body1Regular)
					.foregroundColor(.primaryText)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium2)

				InfoButton(.transactionfee, label: L10n.InfoLink.Title.transactionfee)
					.padding(.bottom, .medium2)
			}
		}

		@ViewBuilder
		func feePayerView(_ viewState: CustomizeFees.ViewState) -> some SwiftUI.View {
			VStack(alignment: .leading) {
				HStack {
					Text(L10n.CustomizeNetworkFees.payFeeFrom)
						.textStyle(.body1Link)
						.foregroundColor(.secondaryText)
						.textCase(.uppercase)

					Spacer()

					Button(L10n.CustomizeNetworkFees.changeButtonTitle) {
						store.send(.view(.changeFeePayerTapped))
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
				if let feePayer = viewState.feePayer {
					AccountCard(account: feePayer)
				} else {
					AppTextField(
						placeholder: "",
						text: .constant(viewState.noFeePayerText)
					)
					.disabled(true)
				}

				if viewState.insufficientBalance {
					StatusMessageView(text: L10n.CustomizeNetworkFees.Warning.insufficientBalance, type: .error)
				} else if viewState.linkingNewAccount {
					StatusMessageView.transactionIntroducesNewAccount()
				}
			}
		}
	}
}

private extension StoreOf<CustomizeFees> {
	var destination: PresentationStoreOf<CustomizeFees.Destination> {
		func scopeState(state: State) -> PresentationState<CustomizeFees.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<CustomizeFees>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /CustomizeFees.Destination.State.selectFeePayer,
			action: CustomizeFees.Destination.Action.selectFeePayer,
			content: { SelectFeePayer.View(store: $0) }
		)
	}
}
