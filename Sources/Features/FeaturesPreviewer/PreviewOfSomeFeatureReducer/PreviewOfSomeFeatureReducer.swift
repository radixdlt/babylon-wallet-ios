import FeaturePrelude

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

	private let withReducer: ((Feature) -> (Reduce<Feature.State, Feature.Action>))?
	public let resultFromAction: (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?
	public init(
		withReducer: ((Feature) -> (Reduce<Feature.State, Feature.Action>))? = nil,
		resultFrom resultFromAction: @escaping (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?
	) {
		self.withReducer = withReducer
		self.resultFromAction = resultFromAction
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: /F.State.previewOf, action: /F.Action.child .. ChildAction.previewOf) {
			(withReducer ?? { Reduce($0._printChanges()) })(Feature())
		}
		Scope(state: /F.State.previewResult, action: /F.Action.child .. ChildAction.previewResult) {
			PreviewResult<Feature.ResultFromFeature>()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .previewOf(.delegate(previewDelegate)):
			if let result = resultFromAction(previewDelegate) {
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
