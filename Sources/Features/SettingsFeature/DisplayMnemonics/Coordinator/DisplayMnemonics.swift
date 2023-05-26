import FactorSourcesClient
import FeaturePrelude

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@Loadable
		public var deviceFactorSources: NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>>)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .task {
				let result = await TaskResult {
					let sources = try await factorSourcesClient.getFactorSources(ofKind: .device)
					let devices = try IdentifiedArrayOf(uncheckedUniqueElements: sources.map(HDOnDeviceFactorSource.init(factorSource:)))
					guard let nonEmpty = NonEmpty(rawValue: devices) else {
						assertionFailure("No device factor sources, really?")
						throw InvalidStateExpectedToAlwaysHaveAtLeastOneDeviceFactorSource()
					}
					return nonEmpty
				}
				return .internal(.loadedFactorSources(result))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedFactorSources(result):
			state.$deviceFactorSources = .init(result: result)
			return .none
		}
	}
}

// MARK: - InvalidStateExpectedToAlwaysHaveAtLeastOneDeviceFactorSource
struct InvalidStateExpectedToAlwaysHaveAtLeastOneDeviceFactorSource: Swift.Error {}
