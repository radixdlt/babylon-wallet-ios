import ComposableArchitecture
import SwiftUI

// MARK: - UserFeedback
public struct NPSSurvey: FeatureReducer {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var feedbackScore: Int? = nil
		public var feedbackReason: String = ""
		public var isUploadingFeedback: Bool = false
	}

	public enum ViewAction: Equatable, Sendable {
		case feedbackScoreTapped(Int)
		case feedbackReasonTextChanged(String)
		case submitFeedbackTapped(score: Int)
		case closeButtonTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case feedbackFilled(NPSSurveyClient.UserFeedback)
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
