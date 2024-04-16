import ComposableArchitecture
import SwiftUI

// MARK: - Settings
public struct Settings: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public var userHasNoP2PLinks: Bool? = nil
		public var shouldWriteDownPersonasSeedPhrase: Bool = false

		public init() {}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case addConnectorButtonTapped
		case securityButtonTapped
		case personasButtonTapped
		case dappsButtonTapped
		case connectorsButtonTapped
		case preferencesButtonTapped
		case troubleshootingButtonTapped
		case debugButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedP2PLinks(P2PLinks)
		case loadedShouldWriteDownPersonasSeedPhrase(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case deleteProfileAndFactorSources(keepInICloudIfPresent: Bool)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case manageP2PLinks(P2PLinksFeature.State)

			case authorizedDapps(AuthorizedDapps.State)
			case personas(PersonasCoordinator.State)
			case debugSettings(DebugSettingsCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case manageP2PLinks(P2PLinksFeature.Action)

			case authorizedDapps(AuthorizedDapps.Action)
			case personas(PersonasCoordinator.Action)
			case debugSettings(DebugSettingsCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.manageP2PLinks, action: /Action.manageP2PLinks) {
				P2PLinksFeature()
			}
			Scope(state: /State.authorizedDapps, action: /Action.authorizedDapps) {
				AuthorizedDapps()
			}
			Scope(state: /State.personas, action: /Action.personas) {
				PersonasCoordinator()
			}
			#if DEBUG
			Scope(state: /State.debugSettings, action: /Action.debugSettings) {
				DebugSettingsCoordinator()
			}
			#endif
		}
	}

	// MARK: Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.dismiss) var dismiss
	@Dependency(\.userDefaults) var userDefaults

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadP2PLinks()
				.merge(with: loadShouldWriteDownPersonasSeedPhrase())

		case .addConnectorButtonTapped:
			state.destination = .manageP2PLinks(.init(destination: .newConnection(.init())))
			return .none

		case .securityButtonTapped:
			// TODO: Implement
			return .none

		case .personasButtonTapped:
			state.destination = .personas(.init())
			return .none

		case .dappsButtonTapped:
			state.destination = .authorizedDapps(.init())
			return .none

		case .connectorsButtonTapped:
			state.destination = .manageP2PLinks(.init())
			return .none

		case .preferencesButtonTapped:
			// TODO: Implement
			return .none

		case .troubleshootingButtonTapped:
			// TODO: Implement
			return .none

		case .debugButtonTapped:
			state.destination = .debugSettings(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedP2PLinks(clients):
			state.userHasNoP2PLinks = clients.isEmpty
			return .none

		case let .loadedShouldWriteDownPersonasSeedPhrase(shouldBackup):
			state.shouldWriteDownPersonasSeedPhrase = shouldBackup
			return .none
		}
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		switch state.destination {
		case .manageP2PLinks:
			loadP2PLinks()
		default:
			.none
		}
	}
}

// MARK: Private
extension Settings {
	private func loadP2PLinks() -> Effect<Action> {
		.run { send in
			await send(.internal(.loadedP2PLinks(
				p2pLinksClient.getP2PLinks()
			)))
		}
	}

	private func loadShouldWriteDownPersonasSeedPhrase() -> Effect<Action> {
		.run { send in
			@Dependency(\.personasClient) var personasClient
			let shouldBackup = try await personasClient.shouldWriteDownSeedPhraseForSomePersona()
			await send(.internal(.loadedShouldWriteDownPersonasSeedPhrase(shouldBackup)))
		}
	}
}
