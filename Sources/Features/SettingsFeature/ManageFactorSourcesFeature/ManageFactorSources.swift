import FeaturePrelude

// MARK: - ManageFactorSources
public struct ManageFactorSources: Sendable, FeatureReducer {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var factorSources: FactorSources?

		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case importOlympiaFactorSource(ImportOlympiaFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case importOlympiaFactorSource(ImportOlympiaFactorSource.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.importOlympiaFactorSource, action: /Action.importOlympiaFactorSource) {
				ImportOlympiaFactorSource()
			}
		}
	}

	// MARK: Action
	public enum ViewAction: Sendable, Equatable {
		case appeared
		case importOlympiaFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationActionOf<ManageFactorSources.Destinations>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadFactorSourcesResult(TaskResult {
					try await factorSourcesClient.getFactorSources()
				})))
			}
		case .importOlympiaFactorSourceButtonTapped:
			state.destination = .importOlympiaFactorSource(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .loadFactorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.importOlympiaFactorSource(.delegate(.dismiss)))):
			state.destination = nil
			return .none
		default:
			return .none
		}
	}
}
