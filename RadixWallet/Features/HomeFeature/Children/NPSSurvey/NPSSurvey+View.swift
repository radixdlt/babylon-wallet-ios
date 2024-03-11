// MARK: - NPSSurvey.View
extension NPSSurvey {
	public struct View: SwiftUI.View {
		public let store: StoreOf<NPSSurvey>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						VStack(spacing: .zero) {
							CloseButton { store.send(.view(.closeButtonTapped)) }
								.flushedLeft
								.padding(.top, .medium3)

							VStack(spacing: .zero) {
								headerView()
								scoreSelectionView()

								Divider()
									.padding(.bottom, .medium1)

								scoreReasonView()
							}
							.padding([.horizontal, .bottom], .large3)
						}
					}
					.separator(.top)
					.footer {
						WithControlRequirements(
							store.feedbackScore,
							forAction: { store.send(.view(.submitFeedbackTapped(score: $0))) }
						) { action in
							Button("Submit Feedback - Thanks!", action: action)
								.buttonStyle(.primaryRectangular)
								.controlState(store.isUploadingFeedback ? .loading(.local) : .enabled)
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
		Text("How’s it Going?")
			.textStyle(.sheetTitle)
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium3)

		Text("How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?")
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
			Text("0 - Not likely")
			Spacer()
			Text("10 - Very likely")
		}
		.textStyle(.body2Regular)
		.foregroundStyle(.app.gray2)
		.padding(.bottom, .large2)
	}

	@ViewBuilder
	private func scoreReasonView() -> some SwiftUI.View {
		Text("What’s the main reason for your score?")
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .small2)

		Text("Optional")
			.textStyle(.body1Regular)
			.foregroundStyle(.app.gray2)
			.padding(.bottom, .medium3)

		AppTextField(
			placeholder: "Let us know...",
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
