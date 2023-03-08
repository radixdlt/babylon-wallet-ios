import FeaturePrelude

// MARK: - ManageFactorSources
public struct ManageFactorSources: Sendable, FeatureReducer {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var factorSources: FactorSources?

		@PresentationState
		public var presentedImportOlympiaFactorSource: ImportOlympiaFactorSource.State?

		public init() {}
	}

	// MARK: Action
	public enum ViewAction: Sendable, Equatable {
		case appeared
		case importOlympiaFactorSourceButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
	}

	public enum ChildAction: Sendable, Equatable {
		case presentedImportOlympiaFactorSource(PresentationActionOf<ImportOlympiaFactorSource>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$presentedImportOlympiaFactorSource, action: /Action.child .. ChildAction.presentedImportOlympiaFactorSource) {
				ImportOlympiaFactorSource()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				await send(.internal(.loadFactorSourcesResult(TaskResult {
					try await factorSourcesClient.getFactorSources()
				})))
			}
		case .importOlympiaFactorSourceButtonTapped:
			let presentedState = ImportOlympiaFactorSource.State()
			return .run { send in
				await send(.child(.presentedImportOlympiaFactorSource(.present(presentedState))))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .loadFactorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}
}
