import ComposableArchitecture
import SwiftUI

// FIXME: Refactor ImportMnemonic
public typealias ExportMnemonic = ImportMnemonic
public typealias DisplayMnemonic = ExportMnemonic

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State? = nil

		public var deviceFactorSources: IdentifiedArrayOf<DisplayEntitiesControlledByMnemonic.State> = []

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDeviceFactorSources(TaskResult<IdentifiedArrayOf<DisplayEntitiesControlledByMnemonic.State>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case row(id: DisplayEntitiesControlledByMnemonic.State.ID, action: DisplayEntitiesControlledByMnemonic.Action)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case displayMnemonic(ImportMnemonic.State)
			case importMnemonics(ImportMnemonicsFlowCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case displayMnemonic(DisplayMnemonic.Action)
			case importMnemonics(ImportMnemonicsFlowCoordinator.Action)
		}

		public init() {}

		public var body: some ReducerOf<Self> {
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
	@Dependency(\.backupsClient) var backupsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.deviceFactorSources, action: /Action.child .. ChildAction.row) {
				DisplayEntitiesControlledByMnemonic()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { send in
				let result = await TaskResult {
					let entitiesForDeviceFactorSources = try await deviceFactorSourceClient.controlledEntities(
						// `nil` means read profile in ProfileStore, instead of using an overriding profile
						nil
					)
					let deviceFactorSources: [DisplayEntitiesControlledByMnemonic.State] = entitiesForDeviceFactorSources.flatMap { ents in

						let states = [ents.babylon, ents.olympia]
							.compactMap { $0 }
							.map {
								DisplayEntitiesControlledByMnemonic.State(
									accountsControlledByKeysOnSameCurve: $0,
									isMnemonicMarkedAsBackedUp: ents.isMnemonicMarkedAsBackedUp,
									isMnemonicPresentInKeychain: ents.isMnemonicPresentInKeychain,
									mode: ents.isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicNeedsImport
								)
							}

						return states
					}
					return deviceFactorSources.asIdentifiable()
				}

				await send(
					.internal(.loadedDeviceFactorSources(result))
				)
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDeviceFactorSources(.success(deviceFactorSources)):
			state.deviceFactorSources = deviceFactorSources
			return .none

		case let .loadedDeviceFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
