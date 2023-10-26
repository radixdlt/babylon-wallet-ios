import ComposableArchitecture
import SwiftUI

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
		case row(id: DisplayEntitiesControlledByMnemonic.State.ID, action: DisplayEntitiesControlledByMnemonic.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Equatable, Reducer {
		public enum State: Sendable, Hashable {
			case displayMnemonic(DisplayMnemonic.State)
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.State)
		}

		public enum Action: Sendable, Equatable {
			case displayMnemonic(DisplayMnemonic.Action)
			case importMnemonicControllingAccounts(ImportMnemonicControllingAccounts.Action)
		}

		public init() {}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.displayMnemonic, action: /Action.displayMnemonic) {
				DisplayMnemonic()
			}

			Scope(state: /State.importMnemonicControllingAccounts, action: /Action.importMnemonicControllingAccounts) {
				ImportMnemonicControllingAccounts()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.keychainClient) var keychainClient

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
						// `nil` means read profile in ProfileStore, instead of using an overriding
						nil
					)
					let deviceFactorSources = entitiesForDeviceFactorSources.map {
						DisplayEntitiesControlledByMnemonic.State(accountsForDeviceFactorSource: $0)
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
				// FIXME: Auto close after 2 minutes?
				state.destination = .displayMnemonic(.init(deviceFactorSource: deviceFactorSource))
				return .none
			case .importMissingMnemonic:
				state.destination = .importMnemonicControllingAccounts(.init(
					entitiesControlledByFactorSource: child.accountsForDeviceFactorSource
				))
				return .none
			}

		case .destination(.presented(.displayMnemonic(.delegate(.failedToLoad)))):
			state.destination = nil
			return .none

		case .destination(.presented(.displayMnemonic(.delegate(.doneViewing)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.importMnemonicControllingAccounts(.delegate(delegatAction)))):
			state.destination = nil
			switch delegatAction {
			case let .skippedMnemonic(factorSourceIDHash):
				return .none

			case let .persistedMnemonicInKeychain(factorSourceID):
				return .none

			case .failedToSaveInKeychain:
				return .none
			}

		default: return .none
		}
	}
}
