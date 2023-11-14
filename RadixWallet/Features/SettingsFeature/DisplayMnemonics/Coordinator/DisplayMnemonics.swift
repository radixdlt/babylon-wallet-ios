import ComposableArchitecture
import SwiftUI

// FIXME: Refactor ImportMnemonic
public typealias ExportMnemonic = ImportMnemonic
public typealias DisplayMnemonic = ExportMnemonic

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State? = nil

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
		case row(
			id: DisplayEntitiesControlledByMnemonic.State.ID,
			action: DisplayEntitiesControlledByMnemonic.Action
		)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Equatable, Reducer {
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
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.deviceFactorSources, action: /Action.child .. ChildAction.row) {
				DisplayEntitiesControlledByMnemonic()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { send in
				let result = await TaskResult {
					let entitiesForDeviceFactorSources = try await deviceFactorSourceClient.controlledEntities(
						// `nil` means read profile in ProfileStore, instead of using an overriding profile
						nil
					)
					let deviceFactorSources = entitiesForDeviceFactorSources.map {
						DisplayEntitiesControlledByMnemonic.State(
							accountsForDeviceFactorSource: $0,
							mode: $0.isMnemonicPresentInKeychain ? .mnemonicCanBeDisplayed : .mnemonicNeedsImport
						)
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
			let deviceFactorSource = child.deviceFactorSource
			switch delegateAction {
			case .displayMnemonic:
				return exportMnemonic(
					factorSourceID: deviceFactorSource.id
				) {
					state.destination = .displayMnemonic(.export($0, title: L10n.RevealSeedPhrase.title))
				}

			case .importMissingMnemonic:
				state.destination = .importMnemonics(.init())
				return .none
			}

		case let .destination(.presented(.displayMnemonic(.delegate(delegateAction)))):
			switch delegateAction {
			case let .doneViewing(idOfBackedUpFactorSource):
				if let idOfBackedUpFactorSource {
					state.deviceFactorSources[id: idOfBackedUpFactorSource]?.backedUp()
				}
			case .notPersisted, .persistedMnemonicInKeychainOnly, .persistedNewFactorSourceInProfile:
				assertionFailure("discrepancy")
			}
			state.destination = nil

			return .none

		case let .destination(.presented(.importMnemonics(.delegate(delegateAction)))):
			switch delegateAction {
			case .finishedEarly:
				state.destination = nil
				return .none
			case let .finishedImportingMnemonics(_, importedIDs, newBDFS):
				for imported in importedIDs {
					state.deviceFactorSources[id: imported.factorSourceID]?.imported()
				}
				state.destination = nil

				if let newBDFS {
					return .run { _ in
						try await factorSourcesClient.saveNewMainBDFS(newBDFS)
					}
				} else {
					return .none
				}
			}
		default: return .none
		}
	}
}

extension DisplayEntitiesControlledByMnemonic.State {
	mutating func imported() {
		self.accountsForDeviceFactorSource.isMnemonicPresentInKeychain = true
		self.mode = .mnemonicCanBeDisplayed
		backedUp()
	}

	mutating func backedUp() {
		self.accountsForDeviceFactorSource.isMnemonicMarkedAsBackedUp = true
	}
}
