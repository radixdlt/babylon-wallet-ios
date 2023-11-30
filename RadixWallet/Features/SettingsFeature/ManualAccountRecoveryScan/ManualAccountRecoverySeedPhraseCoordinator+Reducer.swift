import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoverySeedPhraseCoordinator
public struct ManualAccountRecoverySeedPhraseCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var selected: EntitiesControlledByFactorSource? = nil
		public var deviceFactorSources: IdentifiedArrayOf<EntitiesControlledByFactorSource> = []
		public var path: StackState<Path.State> = .init()
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selected(EntitiesControlledByFactorSource?)
		case addButtonTapped
		case continueButtonTapped(EntitiesControlledByFactorSource)
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDeviceFactorSources(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	// MARK: - Path

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case enterSeedPhrase(ImportMnemonic.State)
			case recoveryComplete(ManualAccountRecoveryComplete.State)
		}

		public enum Action: Sendable, Equatable {
			case enterSeedPhrase(ImportMnemonic.Action)
			case recoveryComplete(ManualAccountRecoveryComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.enterSeedPhrase, action: /Action.enterSeedPhrase) {
				ImportMnemonic()
			}
			Scope(state: /State.recoveryComplete, action: /Action.recoveryComplete) {
				ManualAccountRecoveryComplete()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return updateEntities(state: &state)

		case let .selected(selection):
			state.selected = selection
			return .none

		case .addButtonTapped:
			state.path.append(.enterSeedPhrase(.init(
				header: .init(title: "Enter Legacy Seed Phrase"), // FIXME: Strings
				warning: L10n.EnterSeedPhrase.warning,
				warningOnContinue: nil,
				isWordCountFixed: false,
				persistStrategy: nil, // set?
				bip39Passphrase: "",
				offDeviceMnemonicInfoPrompt: nil
			)))
			return .none

		case .continueButtonTapped:
			state.path.append(.recoveryComplete(.init()))
			return .none

		case .closeButtonTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		case let .path(.popFrom(id: id)):
			.none
		case let .path(.push(id: id, state: pathState)):
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDeviceFactorSources(.success(deviceFactorSources)):
			state.deviceFactorSources = deviceFactorSources
			return .none

		case let .loadedDeviceFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
//			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case let .recoveryComplete(recoveryCompleteAction):
			switch recoveryCompleteAction {
			case .delegate(.finish):
				.run { _ in
					await dismiss()
				}

			default:
				.none
			}

		case let .enterSeedPhrase(importMnemonicAction):
			switch importMnemonicAction {
			case let .delegate(.notPersisted(result)):
				.none

			default:
				.none
			}
		}
	}

	// Helper effects

	private func updateEntities(state: inout State) -> Effect<Action> {
		.run { send in
			let result = await TaskResult {
				try await deviceFactorSourceClient.controlledEntities(nil)
			}
			await send(.internal(.loadedDeviceFactorSources(result)))
		} catch: { error, _ in
			loggerGlobal.error("Error: \(error)")
		}
	}
}

// MARK: - ManualAccountRecoveryComplete
public struct ManualAccountRecoveryComplete: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finish
	}

	// MARK: - Reducer

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			.send(.delegate(.finish))
		}
	}
}
