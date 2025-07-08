import ComposableArchitecture
import SwiftUI

// MARK: - EntitiesControlledByFactorSource + Comparable
extension EntitiesControlledByFactorSource: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.isBDFS {
			return true
		} else if rhs.isBDFS {
			return false
		}

		return lhs.deviceFactorSource.common.addedOn < rhs.deviceFactorSource.common.addedOn
	}
}

// MARK: - ImportMnemonicsFlowCoordinator
struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var mnemonicsLeftToImport: IdentifiedArrayOf<ImportMnemonicControllingAccounts.State> = []
		var imported: OrderedSet<SkippedOrImported> = []
		var skipped: OrderedSet<SkippedOrImported> = []
		var skippedMainBdfs: Bool = false

		enum Context: Sendable, Hashable {
			case fromOnboarding(profile: Profile)
			case notOnboarding

			var profileSnapshotFromOnboarding: Profile? {
				switch self {
				case let .fromOnboarding(profileSnapshot): profileSnapshot
				case .notOnboarding: nil
				}
			}

			var isFromOnboarding: Bool {
				switch self {
				case .fromOnboarding: true
				case .notOnboarding: false
				}
			}
		}

		let context: Context

		@PresentationState
		var destination: Destination.State?

		init(context: Context = .notOnboarding) {
			self.context = context
		}
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.State)
		}

		enum Action: Sendable, Equatable {
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(
				state: /State.importMnemonicControllingAccounts,
				action: /Action.importMnemonicControllingAccounts
			) {
				ImportMnemonicControllingAccounts()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask, closeButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadedToImport(TaskResult<ToImport>)
	}

	struct ToImport: Sendable, Equatable {
		let factorSourcesControllingEntities: IdentifiedArrayOf<EntitiesControlledByFactorSource>
	}

	enum DelegateAction: Sendable, Equatable {
		case finishedImportingMnemonics(
			skipped: OrderedSet<SkippedOrImported>,
			imported: OrderedSet<SkippedOrImported>,
			skippedMainBdfs: Bool
		)

		case finishedEarly(dueToFailure: Bool)
	}

	struct SkippedOrImported: Sendable, Hashable {
		let factorSourceID: FactorSourceIdFromHash
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.transportProfileClient) var transportProfileClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { [context = state.context] send in
				await send(.internal(.loadedToImport(TaskResult {
					let snapshot = if let fromOnboarding = context.profileSnapshotFromOnboarding {
						fromOnboarding
					} else {
						try await transportProfileClient.profileForExport()
					}
					let ents = try await deviceFactorSourceClient.controlledEntities(snapshot)
					try? await clock.sleep(for: .milliseconds(200))
					let factorSourcesControllingEntities: IdentifiedArrayOf<EntitiesControlledByFactorSource> = ents.compactMap { ent in
						let hasAccessToMnemonic = secureStorageClient.containsMnemonicIdentifiedByFactorSourceID(ent.factorSourceID)
						return if hasAccessToMnemonic {
							nil // exclude this mnemonic from mnemonics to import, already present,.
						} else {
							ent // user does not have access to this, needs importing.
						}
					}.asIdentified()

					return ToImport(
						factorSourcesControllingEntities: factorSourcesControllingEntities
					)
				})))
			}
		case .closeButtonTapped:
			.send(.delegate(.finishedEarly(dueToFailure: false)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedToImport(.failure(error)):
			// FIXME: Error handling...?
			loggerGlobal.error("Failed to load entities controlled by profile snapshot")
			errorQueue.schedule(error)
			return .none

		case let .loadedToImport(.success(toImport)):
			let ents = toImport.factorSourcesControllingEntities.sorted().asIdentified()
			var mnemonicsLeftToImport = ents.map {
				ImportMnemonicControllingAccounts.State(
					entitiesControlledByFactorSource: $0,
					isMainBDFS: false
				)
			}.asIdentified()

			state.mnemonicsLeftToImport = mnemonicsLeftToImport
			return nextMnemonicIfNeeded(state: &state)
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .importMnemonicControllingAccounts(.delegate(delegateAction)):
			switch delegateAction {
			case let .skippedMainBDFS(skipped):
				state.skippedMainBdfs = true
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

		default:
			return .none
		}
	}

	func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		guard let destination = state.destination else {
			return nextMnemonicIfNeeded(state: &state)
		}

		switch destination {
		case let .importMnemonicControllingAccounts(substate):
			return nextMnemonicIfNeeded(state: &state)
		}
	}

	private func finishedWith(factorSourceID: FactorSourceIDFromHash, state: inout State) -> Effect<Action> {
		state.mnemonicsLeftToImport.removeAll(where: { $0.id == factorSourceID.asGeneral })
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
			return .send(.delegate(.finishedImportingMnemonics(
				skipped: state.skipped,
				imported: state.imported,
				skippedMainBdfs: state.skippedMainBdfs
			)))
		}
	}
}
