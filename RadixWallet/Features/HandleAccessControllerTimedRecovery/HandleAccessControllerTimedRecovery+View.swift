import SwiftUI

// MARK: - HandleAccessControllerTimedRecovery.View
extension HandleAccessControllerTimedRecovery {
	struct View: SwiftUI.View {
		let store: StoreOf<HandleAccessControllerTimedRecovery>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						alertBanner
						timelineAndExplanationCard
						securityStructureSection
						impactSection
					}
					.padding(.medium3)
					.padding(.bottom, .medium1)
				}
				.background(.secondaryBackground)
				.radixToolbar(
					title: L10n.HandleAccessControllerTimedRecovery.title,
					closeAction: {
						dismiss()
					}
				)
				.footer {
					actionButtons
				}
				.animation(.easeInOut, value: store.isSecurityStructureExpanded)
				.onAppear {
					store.send(.view(.appeared))
				}
			}
		}

		@ViewBuilder
		private var alertBanner: some SwiftUI.View {
			if !store.isKnownRecovery {
				StatusMessageView(
					text: L10n.HandleAccessControllerTimedRecovery.UnknownRecovery.alertMessage,
					type: .error,
					useNarrowSpacing: false
				)
				.padding(.medium3)
				.background(.lightError)
				.cornerRadius(.medium1)
			}
		}

		@ViewBuilder
		private var timelineAndExplanationCard: some SwiftUI.View {
			VStack(alignment: .leading) {
				// Timeline Section
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.HandleAccessControllerTimedRecovery.Timeline.title)
						.textStyle(.secondaryHeader)
						.foregroundStyle(.primaryText)

					VStack(alignment: .leading, spacing: .medium2) {
						if let formattedDate = store.formattedConfirmationDate {
							HStack(spacing: .medium2) {
								Image(.emergencyFallbackCalendar)
									.resizable()
									.frame(width: .large2, height: .large2)
									.foregroundStyle(.iconPrimary)
								VStack(alignment: .leading, spacing: .small3) {
									Text(L10n.HandleAccessControllerTimedRecovery.Timeline.canConfirmAfter)
										.textStyle(.body2Regular)
										.foregroundStyle(.secondaryText)
									Text(formattedDate)
										.textStyle(.body1Header)
										.foregroundStyle(.primaryText)
								}
								Spacer()
							}
						}

						if let countdown = store.formattedCountdown {
							HStack(spacing: .medium2) {
								Image(systemName: "hourglass")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: .large2, height: .large2)
									.foregroundStyle(.iconPrimary)
								VStack(alignment: .leading, spacing: .small3) {
									Text(L10n.HandleAccessControllerTimedRecovery.Timeline.remainingTime)
										.textStyle(.body2Regular)
										.foregroundStyle(.secondaryText)
									Text(countdown)
										.textStyle(.body1Header)
										.foregroundStyle(.primaryText)
								}
								Spacer()
							}
						} else if store.isRecoveryConfirmable {
							HStack(spacing: .medium2) {
								Image(systemName: "checkmark.circle.fill")
									.resizable()
									.frame(width: .large2, height: .large2)
									.foregroundStyle(.app.green1)
								Text(L10n.HandleAccessControllerTimedRecovery.Timeline.confirmable)
									.textStyle(.body1Header)
									.foregroundStyle(.app.green1)
								Spacer()
							}
						}
					}
				}

				// Separator
				Separator()
					.padding(.horizontal, -.medium3)

				// Explanation Section
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.HandleAccessControllerTimedRecovery.Explanation.title)
						.textStyle(.secondaryHeader)
						.foregroundStyle(.primaryText)

					Text(store.isKnownRecovery
						? L10n.HandleAccessControllerTimedRecovery.Explanation.knownMessage
						: L10n.HandleAccessControllerTimedRecovery.Explanation.unknownMessage)
						.textStyle(.body2Regular)
						.foregroundStyle(.secondaryText)
						.lineSpacing(.small3)
				}
			}
			.padding(.medium3)
			.background(.primaryBackground)
			.cornerRadius(.medium1)
		}

		@ViewBuilder
		private var securityStructureSection: some SwiftUI.View {
			if let provisionalSecurityState = store.provisionalSecurityState {
				VStack(alignment: .leading, spacing: .medium2) {
					Text(L10n.HandleAccessControllerTimedRecovery.NewStructure.title)
						.textStyle(.secondaryHeader)
						.foregroundStyle(.primaryText)

					Text(L10n.HandleAccessControllerTimedRecovery.NewStructure.subtitle)
						.textStyle(.body2Regular)
						.foregroundStyle(.secondaryText)

					SecurityStructureOfFactorSourcesView(
						structure: provisionalSecurityState,
						onFactorSourceTapped: { _ in }
					)
					.cornerRadius(.medium1)
				}
				.padding(.medium3)
				.background(.primaryBackground)
				.cornerRadius(.medium1)
			} else {
				VStack(alignment: .leading, spacing: .medium2) {
					HStack(alignment: .center, spacing: .medium2) {
						Image(.error)
							.resizable()
							.frame(width: .large2, height: .large2)
						VStack(alignment: .leading, spacing: .small2) {
							Text(L10n.HandleAccessControllerTimedRecovery.UnknownStructure.title)
								.textStyle(.body1Header)
								.foregroundStyle(.error)

							Text(L10n.HandleAccessControllerTimedRecovery.UnknownStructure.message)
								.textStyle(.body2Regular)
								.foregroundStyle(.primaryText)
								.lineSpacing(.small3)
						}
					}
				}
				.padding(.medium3)
				.background(.lightError)
				.cornerRadius(.medium1)
			}
		}

		@ViewBuilder
		private var impactSection: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium2) {
				Text(L10n.HandleAccessControllerTimedRecovery.Impact.title)
					.textStyle(.secondaryHeader)
					.foregroundStyle(.primaryText)

				VStack(alignment: .leading, spacing: .small3) {
					if store.isKnownRecovery {
						Text(markdown: L10n.HandleAccessControllerTimedRecovery.Impact.confirmMessage, emphasizedColor: .primaryText)
							.textStyle(.body2Regular)
							.foregroundStyle(.secondaryText)
							.lineSpacing(.small3)
					} else {
						Text(markdown: L10n.HandleAccessControllerTimedRecovery.Impact.unknownConfirmDisabled, emphasizedColor: .primaryText)
							.textStyle(.body2Regular)
							.foregroundStyle(.error)
							.lineSpacing(.small3)
					}

					Text(markdown: L10n.HandleAccessControllerTimedRecovery.Impact.cancelMessage, emphasizedColor: .primaryText)
						.textStyle(.body2Regular)
						.foregroundStyle(.secondaryText)
						.lineSpacing(.small3)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(.medium3)
			.background(.primaryBackground)
			.cornerRadius(.medium1)
		}

		@ViewBuilder
		private var actionButtons: some SwiftUI.View {
			if store.isKnownRecovery {
				HStack(spacing: .medium3) {
					Button(L10n.HandleAccessControllerTimedRecovery.Button.cancel) {
						store.send(.view(.stopButtonTapped))
					}
					.buttonStyle(.secondaryRectangular)

					Button(L10n.HandleAccessControllerTimedRecovery.Button.confirm) {
						store.send(.view(.confirmButtonTapped))
					}
					.buttonStyle(.secondaryRectangular)
					.disabled(!store.isRecoveryConfirmable)
				}
			} else {
				Button(L10n.HandleAccessControllerTimedRecovery.Button.cancelUnknown) {
					store.send(.view(.stopButtonTapped))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
			}
		}
	}
}
