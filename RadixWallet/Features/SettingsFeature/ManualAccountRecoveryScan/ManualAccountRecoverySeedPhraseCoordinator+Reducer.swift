import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoverySeedPhraseCoordinator
public struct ManualAccountRecoverySeedPhraseCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var isOlympia: Bool
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

	public enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	// MARK: - Path

	public struct Path: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case enterSeedPhrase(ImportMnemonic.State)
			case accountRecoveryScan(AccountRecoveryScanCoordinator.State)
			case recoveryComplete(ManualAccountRecoveryCompletion.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case enterSeedPhrase(ImportMnemonic.Action)
			case accountRecoveryScan(AccountRecoveryScanCoordinator.Action)
			case recoveryComplete(ManualAccountRecoveryCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.enterSeedPhrase, action: \.enterSeedPhrase) {
				ImportMnemonic()
			}
			Scope(state: \.accountRecoveryScan, action: \.accountRecoveryScan) {
				AccountRecoveryScanCoordinator()
			}
			Scope(state: \.recoveryComplete, action: \.recoveryComplete) {
				ManualAccountRecoveryCompletion()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue

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
			let title = state.isOlympia ? "Enter Legacy Seed Phrase" : "Enter Seed Phrase" // FIXME: Strings

			state.path.append(.enterSeedPhrase(.init(
				header: .init(title: title),
				warning: L10n.EnterSeedPhrase.warning,
				warningOnContinue: nil,
				isWordCountFixed: false,
				persistStrategy: nil, // TODO: Set?
				bip39Passphrase: "",
				offDeviceMnemonicInfoPrompt: nil
			)))
			return .none

		case let .continueButtonTapped(factorSource):
			state.showAccountRecoveryScan(factorSourceID: factorSource.factorSourceID)
			return .none

		case .closeButtonTapped:
			return .run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		default:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDeviceFactorSources(.success(deviceFactorSources)):
			state.deviceFactorSources = deviceFactorSources
			if state.deviceFactorSources.count == 1 {
				state.selected = deviceFactorSources[0]
			}
			return .none

		case let .loadedDeviceFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	private func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case let .enterSeedPhrase(.delegate(importMnemonicAction)):
			switch importMnemonicAction {
			case let .persistedNewFactorSourceInProfile(factorSource):
				do {
					guard case let .device(deviceFactorSource) = factorSource else {
						struct NotDeviceFactorSource: Error {}
						throw NotDeviceFactorSource()
					}

					state.deviceFactorSources.append(
						EntitiesControlledByFactorSource(
							entities: [],
							hiddenEntities: [],
							deviceFactorSource: deviceFactorSource,
							isMnemonicPresentInKeychain: true,
							isMnemonicMarkedAsBackedUp: false
						)
					)

					_ = state.path.popLast()

					state.showAccountRecoveryScan(factorSourceID: deviceFactorSource.id)
				} catch {
					loggerGlobal.error("Failed to add mnemonic \(error)")
					errorQueue.schedule(error)
				}
				return .none
			default:
				return .none
			}

		case .accountRecoveryScan(.delegate(.dismissed)):
			_ = state.path.popLast()
			return .none

		case .accountRecoveryScan(.delegate(.completed)):
			_ = state.path.popLast()
			state.path.append(.recoveryComplete(.init()))
			return .none

		case let .recoveryComplete(.delegate(recoveryCompleteAction)):
			switch recoveryCompleteAction {
			case .finish:
				return .run { send in
					await send(.delegate(.gotoAccountList))
				}
			}

		default:
			return .none
		}
	}

	// Helper effects

	private func updateEntities(state: inout State) -> Effect<Action> {
		.run { [isOlympia = state.isOlympia] send in
			let result = await TaskResult {
				try await deviceFactorSourceClient.controlledEntities(nil)
					.filter { $0.isBDFS == !isOlympia }
			}
			await send(.internal(.loadedDeviceFactorSources(result)))
		} catch: { error, _ in
			loggerGlobal.error("Error: \(error)")
		}
	}
}

private extension ManualAccountRecoverySeedPhraseCoordinator.State {
	mutating func showAccountRecoveryScan(factorSourceID: FactorSourceID.FromHash) {
		path.append(.accountRecoveryScan(.init(
			purpose: .addAccounts(factorSourceID: factorSourceID, olympia: isOlympia)
		)))
	}
}
