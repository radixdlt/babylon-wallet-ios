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

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient
	@Dependency(\.resetWalletClient) var resetWalletClient
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
				.merge(with: overlayActionEffect())
		}
	}

	private func overlayActionEffect() -> Effect<Action> {
		.run { _ in
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
			do {
				for try await _ in resetWalletClient.walletDidReset() {
					guard !Task.isCancelled else { return }
					await send(.delegate(.removedWallet))
				}
			} catch {
				loggerGlobal.error("Failed to iterate over walletDidReset: \(error)")
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
		}
	}
}
