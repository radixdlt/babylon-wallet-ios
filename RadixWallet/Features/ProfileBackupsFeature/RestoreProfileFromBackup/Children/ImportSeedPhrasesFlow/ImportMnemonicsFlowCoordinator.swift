import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator
public struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mnemonicsLeftToImport: IdentifiedArrayOf<EntitiesControlledByFactorSource> = []
		public var imported: OrderedSet<SkippedOrImported> = []
		public var skipped: OrderedSet<SkippedOrImported> = []
		public let profileSnapshot: ProfileSnapshot

		@PresentationState
		public var destination: Destinations.State?

		public init(profileSnapshot: ProfileSnapshot) {
			self.profileSnapshot = profileSnapshot
		}
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.importMnemonicControllingAccounts,
				action: /Action.importMnemonicControllingAccounts
			) {
				ImportMnemonicControllingAccounts()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask, closeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadControlledEntities(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedImportingMnemonics(
			skipped: OrderedSet<SkippedOrImported>,
			imported: OrderedSet<SkippedOrImported>
		)

		case failedToImportAllRequiredMnemonics
		case closeButtonTapped
		case importedMnemonic(forFactorSourceID: FactorSourceID)
	}

	public struct SkippedOrImported: Sendable, Hashable {
		public let factorSourceID: FactorSourceID
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.userDefaultsClient) var userDefaultsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { [snapshot = state.profileSnapshot] send in
				await send(.internal(.loadControlledEntities(TaskResult {
					let ents = try await deviceFactorSourceClient.controlledEntities(snapshot)
					try? await clock.sleep(for: .milliseconds(200))
					return ents.compactMap { ent in
						let hasAccessToMnemonic = secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(ent.factorSourceID)
						return if hasAccessToMnemonic {
							nil // exclude this mnemonic from mnemonics to import, already present,.
						} else {
							ent // user does not have access to this, needs importing.
						}
					}.asIdentifiable()
				})))
			}
		case .closeButtonTapped:
			.send(.delegate(.closeButtonTapped))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(.importMnemonicControllingAccounts(.delegate(delegateAction)))):
			switch delegateAction {
			case let .skippedMnemonic(factorSourceIDHash):
				state.skipped.append(.init(factorSourceID: factorSourceIDHash.embed()))
				return finishedWith(factorSourceID: factorSourceIDHash.embed(), state: &state)

			case let .persistedMnemonicInKeychain(factorSourceID):
				overlayWindowClient.scheduleHUD(.seedPhraseImported)
				state.imported.append(.init(factorSourceID: factorSourceID))
				return .send(.delegate(.importedMnemonic(forFactorSourceID: factorSourceID)))
					.merge(with: finishedWith(factorSourceID: factorSourceID, state: &state))

			case .failedToSaveInKeychain:
				return .send(.delegate(.failedToImportAllRequiredMnemonics))
			}

		case .destination(.dismiss):
			guard let destination = state.destination else {
				return nextMnemonicIfNeeded(state: &state)
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

	private func finishedWith(factorSourceID: FactorSourceID, state: inout State) -> Effect<Action> {
		state.mnemonicsLeftToImport.removeAll(where: { $0.factorSourceID.embed() == factorSourceID })
		return nextMnemonicIfNeeded(state: &state)
	}

	private func nextMnemonicIfNeeded(state: inout State) -> Effect<Action> {
		if let next = state.mnemonicsLeftToImport.first {
			state.destination = .importMnemonicControllingAccounts(.init(entitiesControlledByFactorSource: next))
			return .none
		} else {
			state.destination = nil
			return .send(.delegate(.finishedImportingMnemonics(skipped: state.skipped, imported: state.imported)))
		}
	}
}
