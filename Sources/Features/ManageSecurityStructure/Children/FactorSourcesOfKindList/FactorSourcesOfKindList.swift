import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - SavedOrDraftFactorSource
public enum SavedOrDraftFactorSource<Factor: FactorSourceProtocol>: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID {
		factorSource.id
	}

	public var factorSource: FactorSource {
		switch self {
		case let .draft(factor): return factor.embed()
		case let .saved(factor): return factor.embed()
		}
	}

	case draft(Factor)
	case saved(Factor)
}

// MARK: - NewFactorSourceStateProtocol
public protocol NewFactorSourceStateProtocol {
	init()
}

// MARK: - NewFactorSourceDelegateAction
public enum NewFactorSourceDelegateAction<FactorSourceOfKind: FactorSourceProtocol>: Sendable, Hashable {
	case done(TaskResult<SavedOrDraftFactorSource<FactorSourceOfKind>>)
}

// MARK: - AddableFactorSourceProtocol
public protocol AddableFactorSourceProtocol: FactorSourceProtocol
	where
	FeatureForAddingNew.State: NewFactorSourceStateProtocol,
	FeatureForAddingNew.DelegateAction == NewFactorSourceDelegateAction<Self>,
	FeatureForAddingNew.View: FeatureView,
	FeatureForAddingNew == FeatureForAddingNew.View.Feature
{
	associatedtype FeatureForAddingNew: FeatureReducer & EmptyInitializable
}

// MARK: - FactorSourcesOfKindList
public struct FactorSourcesOfKindList<FactorSourceOfKind>: Sendable, FeatureReducer where FactorSourceOfKind: AddableFactorSourceProtocol {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public enum Mode {
			case onlyPresentList
			case selection
		}

		public let allowSelection: Bool
		public let showHeaders: Bool
		public let mode: Mode

		@Loadable
		public var factorSources: IdentifiedArrayOf<SavedOrDraftFactorSource<FactorSourceOfKind>>? = nil

		public var selectedFactorSourceID: FactorSourceID? = nil

		let selectedFactorSourceControlRequirements: SavedOrDraftFactorSource<FactorSourceOfKind>? = nil

		@PresentationState
		public var destination: Destinations.State? = nil

		var pendingAction: ActionRequiringP2P? = nil

		public init(allowSelection: Bool, mode: Mode, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.mode = mode
			self.showHeaders = showHeaders
		}
	}

	public enum ActionRequiringP2P: Sendable, Hashable {
		case addFactorSource
		case selectFactorSource(SavedOrDraftFactorSource<FactorSourceOfKind>)
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedFactorSource(id: FactorSourceID?)
		case addNewFactorSourceButtonTapped
		case confirmedFactorSource(SavedOrDraftFactorSource<FactorSourceOfKind>)
		case whatIsAFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<SavedOrDraftFactorSource<FactorSourceOfKind>>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseFactorSource(SavedOrDraftFactorSource<FactorSourceOfKind>)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewFactorSource(FactorSourceOfKind.FeatureForAddingNew.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewFactorSource(FactorSourceOfKind.FeatureForAddingNew.Action)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewFactorSource, action: /Action.addNewFactorSource) {
				FactorSourceOfKind.FeatureForAddingNew()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return updateFactorSourcesEffect(state: &state)

		case let .selectedFactorSource(selectedID):
			state.selectedFactorSourceID = selectedID
			return .none

		case let .confirmedFactorSource(factorSource):
			return .send(.delegate(.choseFactorSource(factorSource)))

		case .addNewFactorSourceButtonTapped:
			state.destination = .addNewFactorSource(.init())
			return .none

		case .whatIsAFactorSourceButtonTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedFactorSources(result):
			state.$factorSources = .init(result: result)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addNewFactorSource(.delegate(newFactorSourceAction)))):
			switch newFactorSourceAction {
			case let .done(.success(savedOrDraftFactorSource)):
				state.destination = nil
				state.selectedFactorSourceID = savedOrDraftFactorSource.id
				return updateFactorSourcesEffect(state: &state)
			case let .done(.failure(error)):
				state.destination = nil
				return .none
			}

		default:
			return .none
		}
	}

	private func updateFactorSourcesEffect(state: inout State) -> EffectTask<Action> {
		state.$factorSources = .loading
		return .task {
			let result = await TaskResult {
				let factorSources = try await factorSourcesClient.getFactorSources(type: FactorSourceOfKind.self)
				return IdentifiedArray(uniqueElements: factorSources.map(SavedOrDraftFactorSource.saved))
			}
			return .internal(.loadedFactorSources(result))
		}
	}
}
