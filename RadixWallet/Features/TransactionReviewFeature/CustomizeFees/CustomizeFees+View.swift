
extension CustomizeFees.State {
	// Need to disable, since broken in swiftformat 0.52.7
	// swiftformat:disable redundantClosure

	var viewState: CustomizeFees.ViewState {
		.init(
			title: {
				switch transactionFee.mode {
				case .normal:
					L10n.CustomizeNetworkFees.NormalMode.title
				case .advanced:
					L10n.CustomizeNetworkFees.AdvancedMode.title
				}
			}(),
			description: {
				switch transactionFee.mode {
				case .normal:
					L10n.CustomizeNetworkFees.NormalMode.subtitle
				case .advanced:
					L10n.CustomizeNetworkFees.AdvancedMode.subtitle
				}
			}(),
			modeSwitchTitle: {
				switch transactionFee.mode {
				case .normal:
					L10n.CustomizeNetworkFees.viewAdvancedModeButtonTitle
				case .advanced:
					L10n.CustomizeNetworkFees.viewNormalModeButtonTitle
				}
			}(),
			feePayer: feePayerSelection.selected,
			noFeePayerText: {
				if transactionFee.totalFee.lockFee == .zero {
					L10n.CustomizeNetworkFees.noneRequired
				} else {
					L10n.CustomizeNetworkFees.noAccountSelected
				}
			}(),
			insufficientBalanceMessage: {
				if let feePayer = feePayerSelection.selected {
					if feePayer.xrdBalance < transactionFee.totalFee.lockFee {
						return L10n.CustomizeNetworkFees.Warning.insufficientBalance
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
			}
			.destinations(with: store)
		}

		@ViewBuilder
		func infoView(_ viewState: CustomizeFees.ViewState) -> some SwiftUI.View {
			VStack {
				Text(viewState.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .small1)
				Text(viewState.description)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium2)
			}
		}

		@ViewBuilder
		func feePayerView(_ viewState: CustomizeFees.ViewState) -> some SwiftUI.View {
			VStack(alignment: .leading) {
				HStack {
					Text(L10n.CustomizeNetworkFees.payFeeFrom)
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)

					Spacer()

					Button(L10n.CustomizeNetworkFees.changeButtonTitle) {
						store.send(.view(.changeFeePayerTapped))
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
				if let feePayer = viewState.feePayer?.account {
					SmallAccountCard(
						feePayer.displayName.rawValue,
						identifiable: .address(of: feePayer),
						gradient: .init(feePayer.appearanceID)
					)
					.cornerRadius(.small1)
				} else {
					AppTextField(
						placeholder: "",
						text: .constant(viewState.noFeePayerText)
					)
					.disabled(true)
				}

				if let insufficientBalanceMessage = viewState.insufficientBalanceMessage {
					WarningErrorView(text: insufficientBalanceMessage, type: .error)
				}
			}
		}
	}
}

private extension StoreOf<CustomizeFees> {
	var destination: PresentationStoreOf<CustomizeFees.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
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
