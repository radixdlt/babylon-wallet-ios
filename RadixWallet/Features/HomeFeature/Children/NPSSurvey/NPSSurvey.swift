import ComposableArchitecture
import SwiftUI

// MARK: - UserFeedback
public struct UserFeedback: FeatureReducer {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var feedbackScore: Int?
		public var feedbackReason: String = ""
	}

	public enum ViewAction: Equatable {
		case feedbackScoreTapped(Int)
		case feedbackReasonTextChanged(String)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .feedbackScoreTapped(score):
			state.feedbackScore = score
		case let .feedbackReasonTextChanged(text):
			state.feedbackReason = text
		}

		return .none
	}
}

// MARK: UserFeedback.View
extension UserFeedback {
	public struct View: SwiftUI.View {
		public let store: StoreOf<UserFeedback>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .zero) {
						headerView()
						scoreSelectionView()

						Divider()
							.padding(.bottom, .medium1)

						scoreReasonView()
					}
					.padding(.large3)
				}
				.separator(.top)
				.footer {
					WithControlRequirements(store.feedbackScore, forAction: { loggerGlobal.debug("\(String(describing: $0))") }) { _ in
						Button("Submit Feedback - Thanks!", action: {}).buttonStyle(.primaryRectangular)
					}
				}
			}
		}

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
			FlowLayout(multilineAlignment: .center) {
				ForEach(0 ..< 11) { score in
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
	}
}
