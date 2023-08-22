import Cryptography
import DeviceFactorSourceClient
import FeaturePrelude
import ImportMnemonicFeature

// MARK: - ImportMnemonicsFlowCoordinator
public struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mnemonicsLeftToImport: IdentifiedArrayOf<EntitiesControlledByFactorSource> = []
		public let profileSnapshot: ProfileSnapshot

		@PresentationState
		public var destination: Destinations.State?

		public init(profileSnapshot: ProfileSnapshot) {
			self.profileSnapshot = profileSnapshot
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.importMnemonicControllingAccounts, action: /Action.importMnemonicControllingAccounts) {
				ImportMnemonicControllingAccounts()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
//		case importingMnemonicControllingAccounts(ImportMnemonicControllingAccounts.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadControlledEntities(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedImportingMnemonics
		case failedToImportAllRequiredMnemonics
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

//	public var body: some ReducerProtocolOf<ImportMnemonicsFlowCoordinator> {
//		Reduce(core)
//			.ifLet(\.importMnemonicControllingAccounts, action: /Action.child .. ChildAction.importMnemonicControllingAccounts) {
	//                ImportMnemonicControllingAccounts()
//			}
//	}
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task { [snapshot = state.profileSnapshot] in
				await .internal(.loadControlledEntities(TaskResult {
					try await deviceFactorSourceClient.controlledEntities(snapshot)
				}))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadControlledEntities(.failure(error)):
			// FIXME: Error handling...?
			loggerGlobal.error("Failed to load entities controlled by profile snapshot")
			errorQueue.schedule(error)
			return .none

		case let .loadControlledEntities(.success(factorSourcesControllingEntities)):
			state.mnemonicsLeftToImport = factorSourcesControllingEntities
			return nextMnemonicIfNeeded(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.importMnemonicControllingAccounts(.delegate(.persistedMnemonicInKeychain(factorSourceID))))):

			state.mnemonicsLeftToImport.removeAll(where: { $0.factorSourceID.embed() == factorSourceID })
			return nextMnemonicIfNeeded(state: &state)

		case .destination(.dismiss):
			guard let destination = state.destination else {
				return .none
			}

			switch destination {
			case let .importMnemonicControllingAccounts(substate):
				if substate.entitiesControlledByFactorSource.isSkippable {
					return nextMnemonicIfNeeded(state: &state)
				} else {
					// Skipped a non skippable by use of OS level gestures
					return .send(.delegate(.failedToImportAllRequiredMnemonics))
				}
			}

		default:
			return .none
		}
	}

	private func nextMnemonicIfNeeded(state: inout State) -> EffectTask<Action> {
		if let next = state.mnemonicsLeftToImport.first {
			state.destination = .importMnemonicControllingAccounts(.init(entitiesControlledByFactorSource: next))
			return .none
		} else {
			return .send(.delegate(.finishedImportingMnemonics))
		}
	}
}
