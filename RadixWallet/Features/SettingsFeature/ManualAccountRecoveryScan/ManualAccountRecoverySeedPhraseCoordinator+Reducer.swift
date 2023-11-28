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
				persistStrategy: nil, // TODO: Set?
				bip39Passphrase: "",
				offDeviceMnemonicInfoPrompt: nil
			)))
			return .none

		case let .continueButtonTapped(factorSource):
			state.path.append(.accountRecoveryScan(.init(
				purpose: .addAccounts(factorSourceID: factorSource.factorSourceID, olympia: state.isOlympia)
			)))
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
			if state.deviceFactorSources.count == 1 {
				state.selected = deviceFactorSources[0]
			}
			return .none

		case let .loadedDeviceFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
//			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case let .enterSeedPhrase(.delegate(importMnemonicAction)):
			switch importMnemonicAction {
			case let .notPersisted(mnemonicWithPassphrase):
				do {
					let factorSourceID = try FactorSourceID.FromHash(
						kind: .device,
						mnemonicWithPassphrase: mnemonicWithPassphrase
					)
					//				guard factorSourceID == state.entitiesControlledByFactorSource.factorSourceID else {
					//					overlayWindowClient.scheduleHUD(.wrongMnemonic)
					//					return .none
					//				}

					//				return validate(
					//					mnemonicWithPassphrase: mnemonicWithPassphrase,
					//					accounts: state.entitiesControlledByFactorSource.accounts,
					//					factorSource: state.entitiesControlledByFactorSource.deviceFactorSource
					//				)

					let deviceFactorSource: DeviceFactorSource =
						if state.isOlympia
					{
						try .olympia(mnemonicWithPassphrase: mnemonicWithPassphrase)
					} else {
						try .babylon(mnemonicWithPassphrase: mnemonicWithPassphrase)
					}

					state.deviceFactorSources.append(
						EntitiesControlledByFactorSource(
							entities: [],
							hiddenEntities: [],
							deviceFactorSource: deviceFactorSource,
							isMnemonicPresentInKeychain: false, // TODO: Figure out
							isMnemonicMarkedAsBackedUp: false // TODO: Figure out
						)
					)
				} catch {
					loggerGlobal.error("Failed to add mnemonic \(error)")
				}
				_ = state.path.popLast()
				return .none
			default:
				return .none
			}

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
					.filter { $0.isBDFS == !isOlympia } // TODO: Is this one-to-one?
			}
			await send(.internal(.loadedDeviceFactorSources(result)))
		} catch: { error, _ in
			loggerGlobal.error("Error: \(error)")
		}
	}

	private func validate(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		accounts: [Profile.Network.Account],
		factorSource: DeviceFactorSource
	) -> Effect<Action> {
		.none
//		func fail(error: Swift.Error?) -> Effect<Action> {
//			loggerGlobal.error("Failed to validate all accounts against mnemonic, underlying error: \(String(describing: error))")
//			errorQueue.schedule(MnemonicDidNotValidateAllAccounts())
//			return .none
//		}
//		do {
//			guard try mnemonicWithPassphrase.validatePublicKeys(of: accounts) else {
//				return fail(error: nil)
//			}
//
//			let privateHDFactorSource = try PrivateHDFactorSource(
//				mnemonicWithPassphrase: mnemonicWithPassphrase,
//				factorSource: factorSource
//			)
//
//			return .send(.internal(.validated(privateHDFactorSource)))
//		} catch {
//			return fail(error: error)
//		}
	}
}
