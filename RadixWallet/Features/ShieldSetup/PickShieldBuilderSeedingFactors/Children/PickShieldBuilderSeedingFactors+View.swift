import ComposableArchitecture
import SwiftUI

extension PickShieldBuilderSeedingFactors.State {
	var selectedFactorSourcesStatus: SelectedPrimaryThresholdFactorsStatus {
		shieldBuilder.selectedPrimaryThresholdFactorsStatus()
	}

	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch selectedFactorSourcesStatus {
		case .invalid:
			.general(type: .error, text: L10n.ShieldSetupStatus.invalidCombination)
		case .insufficient:
			.general(type: .error, text: L10n.ShieldSetupStatus.SelectFactors.atLeastOneFactor)
		case .suboptimal:
			.general(type: .warning, text: L10n.ShieldSetupStatus.recommendedFactors)
		case .optimal:
			nil
		}
	}

	var isValidSelection: Bool {
		selectedFactorSourcesStatus == .optimal || selectedFactorSourcesStatus == .suboptimal
	}

	var shouldShowPasswordMessage: Bool {
		selectedFactorSourcesStatus == .invalid(reason: .cannotBeUsedAlone(factorSourceKind: .password))
	}
}

// MARK: - PickShieldBuilderSeedingFactors.View
extension PickShieldBuilderSeedingFactors {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PickShieldBuilderSeedingFactors>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium2)
						.animation(.default, value: store.statusMessageInfo?.type)
						.animation(.default, value: store.shouldShowPasswordMessage)
				}
				.footer {
					Button(L10n.ShieldSetupSelectFactors.buildButtonTitle) {
						store.send(.view(.continueButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.isValidSelection ? .enabled : .disabled)
				}
				.onFirstAppear {
					store.send(.view(.onFirstAppear))
				}
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .small1) {
				topView

				Selection(
					$store.selectedFactorSources.sending(\.view.selectedFactorSourcesChanged),
					from: store.factorSourcesCandidates,
					requiring: .atLeast(1)
				) { item in
					VStack {
						let isFirstOfKind = store.factorSourcesCandidates.first(where: { $0.factorSourceKind == item.value.factorSourceKind }) == item.value
						if isFirstOfKind {
							VStack(alignment: .leading, spacing: .zero) {
								Text(item.value.factorSourceKind.title)
									.textStyle(.body1HighImportance)
								Text(item.value.factorSourceKind.details)
									.textStyle(.body1Regular)

								if item.value.factorSourceKind == .password, store.shouldShowPasswordMessage {
									Text(L10n.ShieldSetupStatus.factorCannotBeUsedByItself)
										.textStyle(.body2Regular)
										.foregroundStyle(.warning)
										.padding(.top, .small3)
								}
							}
							.foregroundStyle(.app.gray2)
							.padding(.top, .medium3)
							.flushedLeft
						}

						FactorSourceCard(
							kind: .instance(factorSource: item.value, kind: .short(showDetails: false)),
							mode: .selection(
								type: .checkmark,
								isSelected: item.isSelected
							)
						)
						.embedInButton(when: item.action)
						.buttonStyle(.inert)
					}
				}

				Button(L10n.ShieldSetupSelectFactors.skipButtonTitle) {
					store.send(.view(.skipButtonTapped))
				}
				.buttonStyle(.primaryText())
				.multilineTextAlignment(.center)
				.padding(.vertical, .medium2)

				Spacer()
			}
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .small1) {
				Image(.pickShieldBuilderSeedingFactors)

				Text(L10n.ShieldSetupSelectFactors.title)
					.textStyle(.sheetTitle)
					.padding(.horizontal, .medium3)

				Text(markdown: L10n.ShieldSetupSelectFactors.subtitle, emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
					.textStyle(.body1Regular)
					.padding(.horizontal, .medium2)
					.padding(.top, .medium3)

				if let statusMessage = store.statusMessageInfo, store.didInteractWithSelection {
					StatusMessageView(
						text: statusMessage.text,
						type: statusMessage.type,
						useNarrowSpacing: true,
						useSmallerFontSize: true,
						emphasizedTextStyle: .body2Header
					)
					.padding(.horizontal, .small1)
					.padding(.top, .small1)
					.flushedLeft
					.onTapGesture {
						if case .invalid = store.selectedFactorSourcesStatus {
							store.send(.view(.invalidReadMoreTapped))
						}
					}
				}
			}
			.foregroundStyle(.primaryText)
			.multilineTextAlignment(.center)
			.padding(.bottom, .medium2)
		}
	}
}
