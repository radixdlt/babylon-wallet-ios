import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State? = nil

		public var deviceFactorSources: IdentifiedArrayOf<DisplayEntitiesControlledByMnemonic.State> = []

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case row(id: DisplayEntitiesControlledByMnemonic.State.ID, action: DisplayEntitiesControlledByMnemonic.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Equatable, Reducer {
		public enum State: Sendable, Hashable {
			case displayMnemonic(DisplayMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case displayMnemonic(DisplayMnemonic.Action)
		}

		public init() {}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.displayMnemonic, action: /Action.displayMnemonic) {
				DisplayMnemonic()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.deviceFactorSources, action: /Action.child .. ChildAction.row) {
				DisplayEntitiesControlledByMnemonic()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { send in
				await send(.internal(.loadedFactorSources(TaskResult {
					try await deviceFactorSourceClient.controlledEntities(nil) // `nil` means read profile in ProfileStore, instead of using an overriding
				})))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedFactorSources(.success(entitiesForDeviceFactorSources)):
			state.deviceFactorSources = .init(
				uniqueElements: entitiesForDeviceFactorSources.map { .init(
					accountsForDeviceFactorSource: $0,
					displayRevealMnemonicLink: true
				) },
				id: \.id
			)

			return .none

		case let .loadedFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load factor source, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .row(id, action: .delegate(.openDetails)):
			guard let deviceFactorSource = state.deviceFactorSources[id: id]?.deviceFactorSource else {
				loggerGlobal.warning("Unable to find factor source in state... strange!")
				return .none
			}
			// FIXME: Auto close after 2 minutes?
			state.destination = .displayMnemonic(.init(deviceFactorSource: deviceFactorSource))
			return .none
		case .destination(.presented(.displayMnemonic(.delegate(.failedToLoad)))):
			state.destination = nil
			return .none

		case .destination(.presented(.displayMnemonic(.delegate(.doneViewing)))):
			state.destination = nil
			return .none

		default: return .none
		}
	}
}
