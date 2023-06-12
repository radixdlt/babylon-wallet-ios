import FeaturePrelude

// MARK: - EmptyInitializable
public protocol EmptyInitializable {
	init()
}

// MARK: - PreviewOfSomeFeatureReducer
public struct PreviewOfSomeFeatureReducer<Feature>: FeatureReducer where Feature: PreviewedFeature {
	public typealias F = Self

	public enum State: Sendable, Hashable, EmptyInitializable {
		public init() {
			self = .previewOf(.init())
		}

		case previewOf(Feature.State)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case previewOf(Feature.Action)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.Action)
	}

	public let resultFromAction: (Feature.Action) -> TaskResult<Feature.ResultFromFeature>?

	public init(
		resultFromAction: @escaping (Feature.Action) -> TaskResult<Feature.ResultFromFeature>?
	) {
		self.resultFromAction = resultFromAction
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: /F.State.previewOf, action: /F.Action.child .. ChildAction.previewOf) {
			Feature()
		}
		Scope(state: /F.State.previewResult, action: /F.Action.child .. ChildAction.previewResult) {
			PreviewResult<Feature.ResultFromFeature>()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
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
