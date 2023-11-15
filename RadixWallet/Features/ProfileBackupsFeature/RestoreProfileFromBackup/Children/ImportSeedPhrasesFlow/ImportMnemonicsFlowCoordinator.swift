import ComposableArchitecture
import SwiftUI

// MARK: - EntitiesControlledByFactorSource + Comparable
extension EntitiesControlledByFactorSource: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.isExplicitMainBDFS {
			return true
		} else if rhs.isExplicitMainBDFS {
			return false
		}

		if lhs.isBDFS {
			return true
		} else if rhs.isBDFS {
			return false
		}

		return lhs.deviceFactorSource.common.addedOn < rhs.deviceFactorSource.common.addedOn
	}
}

// MARK: - ImportMnemonicsFlowCoordinator
public struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mnemonicsLeftToImport: IdentifiedArrayOf<ImportMnemonicControllingAccounts.State> = []
		public var imported: OrderedSet<SkippedOrImported> = []
		public var skipped: OrderedSet<SkippedOrImported> = []
		public var newMainBDFS: NewMainBDFS?
		public enum Context: Sendable, Hashable {
			case fromOnboarding(profileSnapshot: ProfileSnapshot)
			case notOnboarding

			var profileSnapshotFromOnboarding: ProfileSnapshot? {
				switch self {
				case let .fromOnboarding(profileSnapshot): profileSnapshot
				case .notOnboarding: nil
				}
			}
		}

		public let context: Context

		@PresentationState
		public var destination: Destinations.State?

		public init(context: Context = .notOnboarding) {
			self.context = context
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
			imported: OrderedSet<SkippedOrImported>,
			newMainBDFS: NewMainBDFS?
		)

		case finishedEarly(dueToFailure: Bool)
	}

	public struct SkippedOrImported: Sendable, Hashable {
		public let factorSourceID: FactorSource.ID.FromHash
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.backupsClient) var backupsClient

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
			.run { [context = state.context] send in
				await send(.internal(.loadControlledEntities(TaskResult {
					let snapshot = if let fromOnboarding = context.profileSnapshotFromOnboarding {
						fromOnboarding
					} else {
						try await backupsClient.snapshotOfProfileForExport()
					}
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
			.send(.delegate(.finishedEarly(dueToFailure: false)))
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
			let ents = factorSourcesControllingEntities.sorted().asIdentifiable()
			var mnemonicsLeftToImport = ents.map {
				ImportMnemonicControllingAccounts.State(
					entitiesControlledByFactorSource: $0,
					isMainBDFS: false
				)
			}.asIdentifiable()
			let explicitMainBDFSFactorSources = ents.filter(\.isExplicitMain)

			if let explicitMain = explicitMainBDFSFactorSources.first {
				mnemonicsLeftToImport[id: explicitMain.id]?.isMainBDFS = true
				if explicitMainBDFSFactorSources.count > 1 {
					assertionFailure("DISCREPANCY, more than one Main BDFS, this should not happen.")
				}
			} else {
				// No explicit BDFS, needs to treat first Babylon device factor source as implicit main
				if let firstBabylonDeviceFactorSource = ents.filter(\.isBDFS).first {
					mnemonicsLeftToImport[id: firstBabylonDeviceFactorSource.id]?.isMainBDFS = true
				} else {
					assertionFailure("DISCREPANCY, no babylon device factor source, invalid profile.")
				}
			}

			state.mnemonicsLeftToImport = mnemonicsLeftToImport
			return nextMnemonicIfNeeded(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .destination(.presented(.importMnemonicControllingAccounts(.delegate(delegateAction)))):
			switch delegateAction {
			case let .createdNewMainBDFS(skipped, newMainBDFS):
				state.newMainBDFS = newMainBDFS
				state.skipped.append(.init(factorSourceID: skipped))
				return finishedWith(factorSourceID: skipped, state: &state)

			case let .skippedMnemonic(factorSourceIDHash):
				state.skipped.append(.init(factorSourceID: factorSourceIDHash))
				return finishedWith(factorSourceID: factorSourceIDHash, state: &state)

			case let .persistedMnemonicInKeychain(factorSourceID):
				overlayWindowClient.scheduleHUD(.seedPhraseImported)
				state.imported.append(.init(factorSourceID: factorSourceID))
				return finishedWith(factorSourceID: factorSourceID, state: &state)

			case .failedToSaveInKeychain:
				return .send(.delegate(.finishedEarly(dueToFailure: true)))
			}

		case .destination(.dismiss):
			guard let destination = state.destination else {
				return nextMnemonicIfNeeded(state: &state)
			}

			switch destination {
			case let .importMnemonicControllingAccounts(substate):
				if !substate.isMainBDFS {
					return nextMnemonicIfNeeded(state: &state)
				} else {
					// Skipped a main bdfs by use of OS level gestures (thus bypassing warning)
					return .send(.delegate(.finishedEarly(dueToFailure: true)))
				}
			}

		default:
			return .none
		}
	}

	private func finishedWith(factorSourceID: FactorSourceID.FromHash, state: inout State) -> Effect<Action> {
		state.mnemonicsLeftToImport.removeAll(where: { $0.id == factorSourceID.embed() })
		return nextMnemonicIfNeeded(state: &state)
	}

	private func nextMnemonicIfNeeded(state: inout State) -> Effect<Action> {
		if let next = state.mnemonicsLeftToImport.first {
			state.destination = .importMnemonicControllingAccounts(
				next
			)
			return .none
		} else {
			state.destination = nil
			return .send(.delegate(.finishedImportingMnemonics(skipped: state.skipped, imported: state.imported, newMainBDFS: state.newMainBDFS)))
		}
	}
}
