
extension CustomizeFees.State {
	struct Titles: Equatable {
		let title: String
		let description: String
		let modeSwitchTitle: String
	}

	var titles: Titles {
		switch transactionFee.mode {
		case .normal:
			Titles(
				title: L10n.CustomizeNetworkFees.NormalMode.title,
				description: L10n.CustomizeNetworkFees.NormalMode.subtitle,
				modeSwitchTitle: L10n.CustomizeNetworkFees.viewAdvancedModeButtonTitle
			)
		case .advanced:
			Titles(
				title: L10n.CustomizeNetworkFees.AdvancedMode.title,
				description: L10n.CustomizeNetworkFees.AdvancedMode.subtitle,
				modeSwitchTitle: L10n.CustomizeNetworkFees.viewNormalModeButtonTitle
			)
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
}

// MARK: - CustomizeFees.View
extension CustomizeFees {
	@MainActor
	public struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<CustomizeFees>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				let titles = store.titles
				VStack(spacing: .zero) {
					ScrollView {
						VStack(spacing: .zero) {
							VStack {
								infoView(titles)

								Divider()

								feePayerView(
									feePayer: store.feePayer?.account,
									noFeePayerText: store.noFeePayerText,
									insufficientBalance: store.insufficientBalance
								)
								.padding(.top, .small1)
							}
							.padding([.horizontal, .bottom], .medium1)

							let modeStore = store.scope(state: \.modeState, action: \.child.mode)
							switch modeStore.state {
							case .normal:
								if let store = modeStore.scope(state: \.normal, action: \.normalFeesCustomization) {
									NormalFeesCustomization.View(store: store)
								}
							case .advanced:
								if let store = modeStore.scope(state: \.advanced, action: \.advancedFeesCustomization) {
									AdvancedFeesCustomization.View(store: store)
								}
							}
						}
						.padding(.vertical, .medium3)

						Button(titles.modeSwitchTitle) {
							store.send(.view(.toggleMode))
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
			.sheet(item: $store.scope(state: \.destination?.selectFeePayer, action: \.destination.selectFeePayer)) {
				SelectFeePayer.View(store: $0)
			}
//			.destinations(with: $store)
		}

		@ViewBuilder
		func infoView(_ titles: CustomizeFees.State.Titles) -> some SwiftUI.View {
			VStack {
				Text(titles.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .small1)
				Text(titles.description)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium2)
			}
		}

		@ViewBuilder
		func feePayerView(feePayer: Account?, noFeePayerText: String, insufficientBalance: Bool) -> some SwiftUI.View {
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
				if let feePayer {
					AccountCard(account: feePayer)
				} else {
					AppTextField(
						placeholder: "",
						text: .constant(noFeePayerText)
					)
					.disabled(true)
				}

				if insufficientBalance {
					WarningErrorView(text: L10n.CustomizeNetworkFees.Warning.insufficientBalance, type: .error)
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
	func destinations(with store: Perception.Bindable<StoreOf<CustomizeFees>>) -> some View {
//		sheet(item: store.scope(state: \.destination?.selectFeePayer, action: \.destination.selectFeePayer)) {
//			SelectFeePayer.View(store: $0)
//		}
//		sheet(
//			store: store.destination.scope(state: \.selectFeePayer, action: \.selectFeePayer),
//			content: { SelectFeePayer.View(store: $0) }
//		)
	}
}
