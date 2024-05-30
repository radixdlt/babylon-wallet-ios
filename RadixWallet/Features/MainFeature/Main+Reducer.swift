import ComposableArchitecture
import SwiftUI

public struct Main: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var home: Home.State

		public var isOnMainnet = true

		// MARK: - Destination
		@PresentationState
		public var destination: Destination.State?

		public init(home: Home.State) {
			self.home = home
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removedWallet
	}

	public enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Gateway)
		case didResetWallet
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case settings(Settings.State)
		}

		public enum Action: Sendable, Equatable {
			case settings(Settings.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.settings, action: /Action.settings) {
				Settings()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.home, action: /Action.child .. ChildAction.home) {
			Home()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			startAutomaticBackupsEffect()
				.merge(with: gatewayValuesEffect())
				.merge(with: didResetWalletEffect())
		}
	}

	private func startAutomaticBackupsEffect() -> Effect<Action> {
		.run { _ in
			do {
				try await cloudBackupClient.startAutomaticBackups()
			} catch {
				loggerGlobal.notice("cloudBackupClient.startAutomaticBackups failed: \(error)")
			}
		}
	}

	private func gatewayValuesEffect() -> Effect<Action> {
		.run { send in
			for try await gateway in await gatewaysClient.currentGatewayValues() {
				guard !Task.isCancelled else { return }
				loggerGlobal.notice("Changed network to: \(gateway)")
				await send(.internal(.currentGatewayChanged(to: gateway)))
			}
		}
	}

	private func didResetWalletEffect() -> Effect<Action> {
		.run { send in
			for try await action in overlayWindowClient.delegateActions() {
				guard !Task.isCancelled, case .didClearWallet = action else { return }
				await send(.internal(.didResetWallet))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .currentGatewayChanged(currentGateway):
			state.isOnMainnet = currentGateway.network.id == .mainnet
			return .none

		case .didResetWallet:
			return .run { send in
				try await appPreferencesClient.deleteProfileAndFactorSources(true)
				await send(.delegate(.removedWallet))
			} catch: { error, _ in
				loggerGlobal.error("Failed to delete profile: \(error)")
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .settings(.delegate(.didResetWallet)):
			.send(.internal(.didResetWallet))

		default:
			.none
		}
	}
}
