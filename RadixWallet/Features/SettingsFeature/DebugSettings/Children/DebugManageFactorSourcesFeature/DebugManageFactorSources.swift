import ComposableArchitecture
import SwiftUI

// MARK: - DebugManageFactorSources
struct DebugManageFactorSources: Sendable, FeatureReducer {
	// MARK: State
	struct State: Sendable, Hashable {
		var factorSources: FactorSources?

		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
			case addLedger(AddLedgerFactorSource.State)
		}

		enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
			case addLedger(AddLedgerFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: /State.addLedger, action: /Action.addLedger) {
				AddLedgerFactorSource()
			}
		}
	}

	// MARK: Action
	enum ViewAction: Sendable, Equatable {
		case task
		case importOlympiaMnemonicButtonTapped
		case addLedgerButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await factorSources in await factorSourcesClient.factorSourcesAsyncSequence() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.loadFactorSourcesResult(.success(factorSources))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .importOlympiaMnemonicButtonTapped:
			state.destination = .importMnemonic(
				.init(
					isWordCountFixed: false,
					persistStrategy: .init(
						factorSourceKindOfMnemonic: .olympia,
						location: .intoKeychainAndProfile,
						onMnemonicExistsStrategy: .appendWithCryptoParamaters
					)
				)
			)
			return .none

		case .addLedgerButtonTapped:
			state.destination = .addLedger(.init())
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .loadFactorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .importMnemonic(.delegate(.persistedNewFactorSourceInProfile)):
			state.destination = nil
			return .none

		case .addLedger(.delegate(.completed)):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
