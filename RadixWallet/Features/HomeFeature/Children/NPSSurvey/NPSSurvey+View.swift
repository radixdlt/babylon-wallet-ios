// MARK: - NPSSurvey.View
extension NPSSurvey.State {
	var submitButtonControlState: ControlState {
		if feedbackScore == nil {
			return .disabled
		}

		if isUploadingFeedback {
			return .loading(.local)
		}

		return .enabled
	}
}

// MARK: - NPSSurvey.View
extension NPSSurvey {
	struct View: SwiftUI.View {
		let store: StoreOf<NPSSurvey>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .zero) {
							headerView()
							scoreSelectionView()

							Divider()
								.padding(.bottom, .medium1)

							scoreReasonView()
						}
						.padding([.horizontal, .bottom], .large3)
					}
					.withNavigationBar {
						store.send(.view(.closeButtonTapped))
					}
					.footer {
						WithControlRequirements(
							store.feedbackScore,
							forAction: { store.send(.view(.submitFeedbackTapped(score: $0))) }
						) { action in
							Button(L10n.Survey.submitButton, action: action)
								.buttonStyle(.primaryRectangular)
								.controlState(store.submitButtonControlState)
						}
					}
					.presentationDragIndicator(.visible)
				}
			}
		}
	}
}

extension NPSSurvey.View {
	@ViewBuilder
	private func headerView() -> some SwiftUI.View {
		Text(L10n.Survey.title)
			.textStyle(.sheetTitle)
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium3)

		Text(L10n.Survey.subtitle)
			.multilineTextAlignment(.center)
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .large2)
	}

	@ViewBuilder
	private func scoreSelectionView() -> some SwiftUI.View {
		VStack(alignment: .center, spacing: .small2) {
			HStack {
				ForEach(0 ..< 6) { score in
					scoreButton(score)
				}
			}

			HStack {
				ForEach(6 ..< 11) { score in
					scoreButton(score)
				}
			}
		}
		.padding(.bottom, .medium1)

		HStack {
			Text(L10n.Survey.lowestScoreLabel)
			Spacer()
			Text(L10n.Survey.highestScoreLabel)
		}
		.textStyle(.body2Regular)
		.foregroundStyle(.app.gray2)
		.padding(.bottom, .large2)
	}

	@ViewBuilder
	private func scoreReasonView() -> some SwiftUI.View {
		Text(L10n.Survey.Reason.heading)
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .small2)

		Text(L10n.Common.optional)
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray2)
			.padding(.bottom, .medium3)

		AppTextField(
			placeholder: L10n.Survey.Reason.fieldHint,
			text: .init(
				get: { store.feedbackReason },
				set: { store.send(.view(.feedbackReasonTextChanged($0))) }
			)
		)
	}

	@ViewBuilder
	private func scoreButton(_ score: Int) -> some SwiftUI.View {
		let isSelected = score == store.feedbackScore

		Button(action: {
			store.send(.view(.feedbackScoreTapped(score)))
		}) {
			Text("\(score)")
				.textStyle(.body1HighImportance)
				.foregroundColor(isSelected ? .app.white : .app.gray1)
				.frame(.small)
				.background(isSelected ? .app.gray1 : .clear)
				.clipShape(Circle())
				.overlay(
					Circle()
						.stroke(isSelected ? .app.gray1 : .app.gray3, lineWidth: 1)
				)
		}
	}
}
