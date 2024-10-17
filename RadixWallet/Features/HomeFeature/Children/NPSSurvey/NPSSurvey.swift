import ComposableArchitecture
import SwiftUI

// MARK: - UserFeedback
struct NPSSurvey: FeatureReducer {
	@ObservableState
	struct State: Hashable, Sendable {
		var feedbackScore: Int? = nil
		var feedbackReason: String = ""
		var isUploadingFeedback: Bool = false
	}

	enum ViewAction: Equatable, Sendable {
		case feedbackScoreTapped(Int)
		case feedbackReasonTextChanged(String)
		case submitFeedbackTapped(score: Int)
		case closeButtonTapped
	}

	enum DelegateAction: Equatable, Sendable {
		case feedbackFilled(NPSSurveyClient.UserFeedback)
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .feedbackScoreTapped(score):
			state.feedbackScore = score
		case let .feedbackReasonTextChanged(text):
			state.feedbackReason = text
		case let .submitFeedbackTapped(score):
			return .send(.delegate(.feedbackFilled(
				.init(npsScore: score, reason: state.feedbackReason.nilIfEmpty)
			)))
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}

		return .none
	}
}
