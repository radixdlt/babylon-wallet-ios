import FactorSourcesClient
import FeaturePrelude
import ImportMnemonicFeature
import SecureStorageClient

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var displayMnemonic: DisplayMnemonic.State?

		public var deviceFactorSources: IdentifiedArrayOf<DisplayMnemonicRow.State> = []

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<HDOnDeviceFactorSource>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case row(id: DisplayMnemonicRow.State.ID, action: DisplayMnemonicRow.Action)
		case details(PresentationAction<DisplayMnemonic.Action>)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task {
				let result = await TaskResult {
					let sources = try await factorSourcesClient.getFactorSources(ofKind: .device)
					let devices = try IdentifiedArrayOf(uncheckedUniqueElements: sources.map(HDOnDeviceFactorSource.init(factorSource:)))
					return devices
				}
				return .internal(.loadedFactorSources(result))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedFactorSources(.success(sources)):
			state.deviceFactorSources = .init(uniqueElements: sources.map { .init(deviceFactorSource: $0) }, id: \.id)
			return .none
		case let .loadedFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load factor source, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .row(id, action: .delegate(.openDetails)):
			guard let deviceFactorSource = state.deviceFactorSources[id: id]?.deviceFactorSource else {
				loggerGlobal.warning("Unable to find factor source in state... strange!")
				return .none
			}
			state.displayMnemonic = .init(deviceFactorSource: deviceFactorSource)
			return .none
		case .details(.presented(.delegate(.failedToLoad))):
			state.displayMnemonic = nil
			return .none
		default: return .none
		}
	}
}

// MARK: - InvalidStateExpectedToAlwaysHaveAtLeastOneDeviceFactorSource
struct InvalidStateExpectedToAlwaysHaveAtLeastOneDeviceFactorSource: Swift.Error {}
