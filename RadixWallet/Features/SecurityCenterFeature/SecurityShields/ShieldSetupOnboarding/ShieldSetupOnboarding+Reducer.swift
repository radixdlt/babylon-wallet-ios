import ComposableArchitecture
import SwiftUI

@Reducer
struct ShieldSetupOnboarding: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		var steps: [ShieldSetupOnboardingStep] = ShieldSetupOnboardingStep.allCases
		var selectedStepIndex = 0

		var isLastStep: Bool {
			selectedStepIndex == steps.count - 1
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case selectedStepIndexChanged(Int)
		case nextButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case start
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selectedStepIndexChanged(index):
			state.selectedStepIndex = index
			return .none
		case .nextButtonTapped:
			if state.isLastStep {
				return .send(.delegate(.start))
			} else {
				state.selectedStepIndex += 1
				return .none
			}
		}
	}
}
