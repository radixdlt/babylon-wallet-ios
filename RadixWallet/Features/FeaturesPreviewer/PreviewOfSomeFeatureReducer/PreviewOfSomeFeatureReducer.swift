import ComposableArchitecture
import SwiftUI

// MARK: - PreviewOfSomeFeatureReducer
struct PreviewOfSomeFeatureReducer<Feature>: FeatureReducer where Feature: PreviewedFeature {
	typealias F = Self

	enum State: Sendable, Hashable, EmptyInitializable {
		init() {
			self = .previewOf(.init())
		}

		case previewOf(Feature.State)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.State)
	}

	enum ChildAction: Sendable, Equatable {
		case previewOf(Feature.Action)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.Action)
	}

	let resultFromAction: (Feature.Action) -> TaskResult<Feature.ResultFromFeature>?

	init(
		resultFromAction: @escaping (Feature.Action) -> TaskResult<Feature.ResultFromFeature>?
	) {
		self.resultFromAction = resultFromAction
	}

	var body: some ReducerOf<Self> {
		Scope(state: /F.State.previewOf, action: /F.Action.child .. ChildAction.previewOf) {
			Feature()
		}
		Scope(state: /F.State.previewResult, action: /F.Action.child .. ChildAction.previewResult) {
			PreviewResult<Feature.ResultFromFeature>()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .previewOf(action):
			if let result = resultFromAction(action) {
				state = .previewResult(.init(previewResult: result))
			}
			return .none

		case .previewResult(.delegate(.restart)):
			state = .previewOf(.init())
			return .none

		default: return .none
		}
	}
}
