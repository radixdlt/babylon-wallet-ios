import AddLedgerFactorSourceFeature
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
			case addLedger(AddLedgerFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case importOlympiaFactorSource(ImportOlympiaFactorSource.Action)
			case addLedger(AddLedgerFactorSource.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.importOlympiaFactorSource, action: /Action.importOlympiaFactorSource) {
				ImportOlympiaFactorSource()
			}
			Scope(state: /State.addLedger, action: /Action.addLedger) {
				AddLedgerFactorSource()
			}
		}
	}

	// MARK: Action
	public enum ViewAction: Sendable, Equatable {
		case task
		case importOlympiaFactorSourceButtonTapped
		case addLedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await factorSources in await factorSourcesClient.factorSourcesAsyncSequence() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.loadFactorSourcesResult(.success(factorSources))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		case .importOlympiaFactorSourceButtonTapped:
			state.destination = .importOlympiaFactorSource(.init(shouldPersist: true))
			return .none
		case .addLedgerButtonTapped:
			state.destination = .addLedger(.init())
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
		case .destination(.presented(.importOlympiaFactorSource(.delegate(.persisted)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.addLedger(.delegate(.completed(ledger))))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
