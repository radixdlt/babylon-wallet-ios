import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonic
public struct DisplayMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let deviceFactorSource: DeviceFactorSource

		public var importMnemonic: ImportMnemonic.State?

		public init(deviceFactorSource: DeviceFactorSource) {
			self.deviceFactorSource = deviceFactorSource
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadMnemonicResult(TaskResult<MnemonicWithPassphrase?>)
	}

	public enum ChildAction: Sendable, Equatable {
		case importMnemonic(ImportMnemonic.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToLoad
		case doneViewing(isBackedUp: Bool, factorSourceID: FactorSource.ID.FromHash)
	}

	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.importMnemonic, action: /Action.child .. ChildAction.importMnemonic) {
				ImportMnemonic()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { [deviceFactorSource = state.deviceFactorSource] send in
				let factorSourceID = deviceFactorSource.id
				let result = await TaskResult {
					try secureStorageClient.loadMnemonic(
						factorSourceID: factorSourceID,
						purpose: .displaySeedPhrase
					)
				}
				await send(.internal(.loadMnemonicResult(result)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadMnemonicResult(.success(maybeMnemonicWithPassphrase)):
			guard let mnemonicWithPassphrase = maybeMnemonicWithPassphrase else {
				loggerGlobal.error("Mnemonic was nil")
				return .send(.delegate(.failedToLoad))
			}

			state.importMnemonic = .init(
				warning: L10n.RevealSeedPhrase.warning,
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				readonlyMode: .init(
					context: .fromSettings,
					factorSourceKind: state.deviceFactorSource.factorSourceKind
				)
			)
			return .none

		case let .loadMnemonicResult(.failure(error)):
			loggerGlobal.error("Error loading mnemonic: \(error)")
			return .send(.delegate(.failedToLoad))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .importMnemonic(.delegate(.doneViewing(markedMnemonicAsBackedUp))):
			let isBackedUp = markedMnemonicAsBackedUp ?? true
			state.importMnemonic = nil
			return .send(
				.delegate(
					.doneViewing(
						isBackedUp: isBackedUp,
						factorSourceID: state.deviceFactorSource.id
					)
				)
			)
		default: return .none
		}
	}
}
