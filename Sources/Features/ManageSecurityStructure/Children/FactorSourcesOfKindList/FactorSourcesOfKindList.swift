import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - SavedOrDraftFactorSource
public enum SavedOrDraftFactorSource<Factor: FactorSourceProtocol, Extra: Sendable & Hashable>: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID {
		factorSource.id
	}

	public var factorSource: FactorSource {
		switch self {
		case let .draft(factor, _): return factor.embed()
		case let .saved(factor): return factor.embed()
		}
	}

	case draft(Factor, Extra)
	case saved(Factor)
}

extension SavedOrDraftFactorSource where Extra == EquatableVoid {
	public static func draft(_ factor: Factor) -> Self {
		//        Self.draft(factor, EquatableVoid())
		fatalError()
	}

	public static func saved(_ factor: Factor) -> Self {
		//        Self.saved(factor, EquatableVoid())
		fatalError()
	}
}

// MARK: - FactorSourcesOfKindList
public struct FactorSourcesOfKindList<FactorSourceOfKind, Extra: Sendable & Hashable>: Sendable, FeatureReducer where FactorSourceOfKind: FactorSourceProtocol {
	// MARK: - State

	public typealias Factor = SavedOrDraftFactorSource<FactorSourceOfKind, Extra>

	public struct State: Sendable, Hashable {
		public enum Mode {
			case onlyPresentList
			case selection
		}

		public let mode: Mode

		public var factorSources: IdentifiedArrayOf<Factor>

		public var selectedFactorSourceID: FactorSourceID? = nil

		let selectedFactorSourceControlRequirements: SavedOrDraftFactorSource<FactorSourceOfKind, Extra>? = nil

		@PresentationState
		public var destination: Destinations.State? = nil

		public init(
			mode: Mode,
			factorSources: IdentifiedArrayOf<SavedOrDraftFactorSource<FactorSourceOfKind, Extra>>?
		) {
			self.mode = mode
			if let factorSources {
				self.factorSources = factorSources
			} else {
				self.factorSources = []
			}
		}

		public init(
			mode: Mode,
			factorSource: SavedOrDraftFactorSource<FactorSourceOfKind, Extra>
		) {
			self.init(mode: mode, factorSources: [factorSource])
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedFactorSource(id: FactorSourceID?)
		case addNewFactorSourceButtonTapped
		case confirmedFactorSource(SavedOrDraftFactorSource<FactorSourceOfKind, Extra>)
		case whatIsAFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<SavedOrDraftFactorSource<FactorSourceOfKind, Extra>>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseFactorSource(SavedOrDraftFactorSource<FactorSourceOfKind, Extra>)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind, Extra>.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewFactorSource(ManageSomeFactorSource<FactorSourceOfKind, Extra>.Action)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewFactorSource, action: /Action.addNewFactorSource) {
				ManageSomeFactorSource<FactorSourceOfKind, Extra>()
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
		case let .loadedFactorSources(.success(loadedFactors)):
			state.factorSources.append(contentsOf: loadedFactors)
			return .none
		case let .loadedFactorSources(.failure(error)):
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to load factor sources from profile: \(error)")
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
		.task {
			let result = await TaskResult {
				let factorSources = try await factorSourcesClient.getFactorSources(type: FactorSourceOfKind.self)
				return IdentifiedArray(uniqueElements: factorSources.map(SavedOrDraftFactorSource<FactorSourceOfKind, Extra>.saved))
			}
			return .internal(.loadedFactorSources(result))
		}
	}
}
