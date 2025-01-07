extension RegularAccessSetup.State {
	var validatedRoleStatus: SelectedFactorSourcesForRoleStatus {
		shieldBuilder.selectedFactorSourcesForRoleStatus(role: .primary)
	}

	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch validatedRoleStatus {
		case .invalid:
			.init(type: .warning, text: L10n.ShieldSetupStatus.invalidCombination)
		case .insufficient:
			.init(type: .error, text: L10n.ShieldSetupStatus.Transactions.atLeastOneFactor)
		case .suboptimal, .optimal:
			nil
		}
	}

	var canContinue: Bool {
		validatedRoleStatus != .insufficient
	}
}

// MARK: - RegularAccessSetup.View
extension RegularAccessSetup {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RegularAccessSetup>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium2)
						.padding(.top, .small2)
				}
				.radixToolbar(title: L10n.ShieldWizardRegularAccess.Step.title)
				.footer {
					Button(L10n.Common.continue) {
						store.send(.view(.continueButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.canContinue ? .enabled : .disabled)
				}
				.task {
					store.send(.view(.task))
				}
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .small1) {
				topView
			}
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				Image(.regularAccessSetup)
					.padding(.bottom, .small3)

				Text(L10n.ShieldWizardRegularAccess.title)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)

				Text(L10n.ShieldWizardRegularAccess.subtitle)
					.textStyle(.body1Regular)
					.multilineTextAlignment(.leading)
					.flushedLeft

				if let statusMessage = store.statusMessageInfo {
					StatusMessageView(
						text: statusMessage.text,
						type: statusMessage.type,
						useNarrowSpacing: true,
						useSmallerFontSize: true,
						emphasizedTextStyle: .body2Header
					)
					.padding(.horizontal, .small1)
					.padding(.vertical, .medium3)
					.flushedLeft
				}
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium2)
		}
	}
}
