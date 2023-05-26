import FeaturePrelude
import ImportMnemonicFeature
import SecureStorageClient

// MARK: - DisplayMnemonic
public struct DisplayMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let deviceFactorSource: HDOnDeviceFactorSource

		public var importMnemonic: ImportMnemonic.State?

		public init(deviceFactorSource: HDOnDeviceFactorSource) {
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
	}

	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task { [factorSourceID = state.deviceFactorSource.id] in

				let result = await TaskResult {
					try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .debugOnlyInspect)
				}
				return .internal(.loadMnemonicResult(result))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadMnemonicResult(.success(maybeMnemonic)):
			guard let mnemonic = maybeMnemonic else {
				loggerGlobal.error("Mnemonic was nil")
				return .send(.delegate(.failedToLoad))
			}
			state.importMnemonic = .init(mnemonic: mnemonic.mnemonic)
			return .none

		case let .loadMnemonicResult(.failure(error)):
			loggerGlobal.error("Error loading mnemonic: \(error)")
			return .send(.delegate(.failedToLoad))
		}
	}
}
