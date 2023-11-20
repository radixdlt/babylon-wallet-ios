import ComposableArchitecture
import SwiftUI

// MARK: - DebugManageFactorSources
public struct DebugManageFactorSources: Sendable, FeatureReducer {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var factorSources: FactorSources?

		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
			case addLedger(AddLedgerFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
			case addLedger(AddLedgerFactorSource.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.importMnemonic, action: /Action.importMnemonic) {
				ImportMnemonic()
			}
			Scope(state: /State.addLedger, action: /Action.addLedger) {
				AddLedgerFactorSource()
			}
		}
	}

	// MARK: Action
	public enum ViewAction: Sendable, Equatable {
		case task
		case importOlympiaMnemonicButtonTapped
		case addLedgerButtonTapped
		case addOffDeviceMnemonicButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadFactorSourcesResult(TaskResult<FactorSources>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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
			state.destination = .importMnemonic(.init(persistStrategy: .init(mnemonicForFactorSourceKind: .onDevice(.olympia), location: .intoKeychainAndProfile)))
			return .none

		case .addOffDeviceMnemonicButtonTapped:
			state.destination = .importMnemonic(.init(persistStrategy: .init(mnemonicForFactorSourceKind: .offDevice, location: .intoKeychainAndProfile)))
			return .none

		case .addLedgerButtonTapped:
			state.destination = .addLedger(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadFactorSourcesResult(.success(factorSources)):
			state.factorSources = factorSources
			return .none
		case let .loadFactorSourcesResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
