import ComposableArchitecture
import SwiftUI

// FIXME: Refactor ImportMnemonic
typealias ExportMnemonic = ImportMnemonic
typealias DisplayMnemonic = ExportMnemonic

// MARK: - DisplayMnemonics
struct DisplayMnemonics: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State? = nil

		var deviceFactorSources: IdentifiedArrayOf<DisplayEntitiesControlledByMnemonic.State> = []
		fileprivate var problems: [SecurityProblem]?
		fileprivate var entities: IdentifiedArrayOf<EntitiesControlledByFactorSource>?

		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case setSecurityProblems([SecurityProblem])
		case setEntities(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
		case setDeviceFactorSources(IdentifiedArrayOf<DisplayEntitiesControlledByMnemonic.State>)
	}

	enum ChildAction: Sendable, Equatable {
		case row(id: DisplayEntitiesControlledByMnemonic.State.ID, action: DisplayEntitiesControlledByMnemonic.Action)
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case displayMnemonic(ImportMnemonic.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
		}

		enum Action: Sendable, Equatable {
			case displayMnemonic(DisplayMnemonic.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
		}

		init() {}

		var body: some ReducerOf<Self> {
			Scope(state: /State.displayMnemonic, action: /Action.displayMnemonic) {
				DisplayMnemonic()
			}
			Scope(state: /State.importMnemonics, action: /Action.importMnemonics) {
				ImportMnemonicsFlowCoordinator()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.securityCenterClient) var securityCenterClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.deviceFactorSources, action: /Action.child .. ChildAction.row) {
				DisplayEntitiesControlledByMnemonic()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			securityProblemsEffect()
				.merge(with: entitiesEffect())
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setSecurityProblems(problems):
			state.problems = problems
			return deviceFactorSourcesEffect(state: state)

		case let .setEntities(.success(entities)):
			state.entities = entities
			return deviceFactorSourcesEffect(state: state)

		case let .setEntities(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
			errorQueue.schedule(error)
			return .none

		case let .setDeviceFactorSources(deviceFactorSources):
			state.deviceFactorSources = deviceFactorSources
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .row(id, action: .delegate(delegateAction)):
			guard let child = state.deviceFactorSources[id: id] else {
				loggerGlobal.warning("Unable to find factor source in state... strange!")
				return .none
			}
			switch delegateAction {
			case .displayMnemonic:
				return exportMnemonic(
					factorSourceID: child.id.factorSourceID
				) {
					state.destination = .displayMnemonic(.export($0, title: L10n.RevealSeedPhrase.title, context: .fromSettings))
				}

			case .importMissingMnemonic:
				state.destination = .importMnemonics(.init())
				return .none
			}

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .displayMnemonic(.delegate(delegateAction)):
			switch delegateAction {
			case let .doneViewing(idOfBackedUpFactorSource):
				if let idOfBackedUpFactorSource {
					state.deviceFactorSources[id: .singleCurve(idOfBackedUpFactorSource, isOlympia: true)]?.backedUp()
					state.deviceFactorSources[id: .singleCurve(idOfBackedUpFactorSource, isOlympia: false)]?.backedUp()
				}
			case .notPersisted, .persistedMnemonicInKeychainOnly, .persistedNewFactorSourceInProfile:
				assertionFailure("discrepancy")
			}
			state.destination = nil

			return .none

		case let .importMnemonics(.delegate(delegateAction)):
			switch delegateAction {
			case .finishedEarly:
				state.destination = nil
				return .none
			case let .finishedImportingMnemonics(_, importedIDs, notYetSavedNewMainBDFS):
				assert(notYetSavedNewMainBDFS == nil, "Discrepancy, new Main BDFS should already have been saved.")
				for imported in importedIDs {
					state.deviceFactorSources[id: .singleCurve(imported.factorSourceID, isOlympia: true)]?.imported()
					state.deviceFactorSources[id: .singleCurve(imported.factorSourceID, isOlympia: false)]?.imported()
				}
				state.destination = nil

				return .none
			}

		default:
			return .none
		}
	}

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems(.securityFactors) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}

	private func entitiesEffect() -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				try await deviceFactorSourceClient.controlledEntities(
					// `nil` means read profile in ProfileStore, instead of using an overriding profile
					nil
				)
			}
			await send(.internal(.setEntities(result)))
		}
	}

	private func deviceFactorSourcesEffect(state: State) -> Effect<Action> {
		guard let problems = state.problems, let entities = state.entities else {
			return .none
		}
		return .run { send in
			let comparableEntities = entities.flatMap { ents in
				[ents.babylon, ents.olympia]
					.compactMap { $0 }
					.map {
						ComparableEntities(
							state: .init(entitiesControlledByKeysOnSameCurve: $0, problems: problems),
							deviceFactorSource: ents.deviceFactorSource
						)
					}
			}
			let result = comparableEntities
				.sorted()
				.map(\.state)
				.asIdentified()
			await send(.internal(.setDeviceFactorSources(result)))
		}
	}
}

extension DisplayEntitiesControlledByMnemonic.State {
	mutating func imported() {
		self.isMnemonicPresentInKeychain = true
		self.mode = .mnemonicCanBeDisplayed
		backedUp()
	}

	mutating func backedUp() {
		self.isMnemonicMarkedAsBackedUp = true
	}
}

// MARK: - DisplayMnemonics.ComparableEntities
private extension DisplayMnemonics {
	/// A helper struct to sort mnemonics using the following criteria:
	/// 1) First should be the one associated with main device factor source.
	/// 2) Last should be those with Olympia device factor source.
	/// 3) In the middle will show those with babylon device factor source sorted by date added.
	struct ComparableEntities: Comparable {
		let state: DisplayEntitiesControlledByMnemonic.State
		let deviceFactorSource: DeviceFactorSource

		static func < (lhs: Self, rhs: Self) -> Bool {
			let lhs = lhs.deviceFactorSource
			let rhs = rhs.deviceFactorSource
			if lhs.isExplicitMain {
				return true
			} else if rhs.isExplicitMain {
				return false
			} else {
				if lhs.isBDFS, rhs.isBDFS {
					return lhs.common.addedOn < rhs.common.addedOn
				} else {
					return lhs.isBDFS
				}
			}
		}
	}
}
