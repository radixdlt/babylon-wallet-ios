import AddFactorSourceFactorSourceFeature
import FactorSourcesClient
import FeaturePrelude
import NewConnectionFeature
import P2PLinksClient
import Profile

// MARK: - AddableFactorSourceProtocol
public protocol AddableFactorSourceProtocol: FactorSourceProtocol {
	associatedtype FeatureForAddingNew: FeatureReducer
}

// MARK: - SelectedFactorSourceOfKindControlRequirements
struct SelectedFactorSourceOfKindControlRequirements<FactorSourceOfKind: FactorSourceProtocol>: Hashable {
	let selectedFactorSource: FactorSourceOfKind
}

// MARK: - FactorSourcesOfKindList
public struct FactorSourcesOfKindList<FactorSourceOfKind>: Sendable, FeatureReducer where FactorSourceOfKind: AddableFactorSourceProtocol {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public enum Context {
			case settings
			case ledgerSelection
		}

		public let allowSelection: Bool
		public let showHeaders: Bool
		public let context: Context

		public var hasAConnectorExtension: Bool = false

		@Loadable
		public var factorSources: IdentifiedArrayOf<FactorSourceOfKind>? = nil

		public var selectedFactorSourceID: FactorSourceID.FromHash? = nil
		public typealias SelectedFactorSourceControlRequirements = SelectedFactorSourceOfKindControlRequirements<FactorSourceOfKind>
		let selectedFactorSourceControlRequirements: SelectedFactorSourceControlRequirements? = nil

		@PresentationState
		public var destination: Destinations.State? = nil

		var pendingAction: ActionRequiringP2P? = nil

		public init(allowSelection: Bool, context: Context, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.context = context
			self.showHeaders = showHeaders
		}
	}

	public enum ActionRequiringP2P: Sendable, Hashable {
		case addFactorSource
		case selectFactorSource(FactorSourceOfKind)
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedFactorSource(id: FactorSourceID?)
		case addNewFactorSourceButtonTapped
		case confirmedFactorSource(FactorSourceOfKind)
		case whatIsAFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<FactorSourceOfKind>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseFactorSource(FactorSourceOfKind)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewFactorSource(FactorSourceOfKind.FeatureForAddingNew.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewFactorSource(FactorSourceOfKind.FeatureForAddingNew.Action)
		}

		public init() {
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
			return performActionRequiringP2PEffect(.selectFactorSource(factorSource), in: &state)

		case .addNewFactorSourceButtonTapped:
			return performActionRequiringP2PEffect(.addFactorSource, in: &state)

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
			case let .completed(factorSource):
				state.destination = nil
				state.selectedFactorSourceID = factorSource.id
				return updateFactorSourcesEffect(state: &state)
			case .failedToAddFactorSource:
				state.destination = nil
				return .none
			case .dismiss:
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
				return IdentifiedArray(uniqueElements: factorSources)
			}
			return .internal(.loadedFactorSources(result))
		}
	}
}
