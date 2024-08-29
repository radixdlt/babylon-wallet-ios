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

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case task
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
	}

	@CasePathable
	public enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Gateway)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case settings(Settings.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case settings(Settings.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.settings, action: \.settings) {
				Settings()
			}
		}
	}

	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.cloudBackupClient) var cloudBackupClient
	@Dependency(\.securityCenterClient) var securityCenterClient
	@Dependency(\.accountLockersClient) var accountLockersClient
	@Dependency(\.deepLinkHandlerClient) var deepLinkHandlerClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.home, action: \.child.home) {
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
			// At fresh app start, handle deepLink only when app goes to main state.
			// While splash screen is shown, or during the onboarding, the deepLink is buffered.
			deepLinkHandlerClient.handleDeepLink()

			return startAutomaticBackupsEffect()
				.merge(with: startMonitoringSecurityCenterEffect())
				.merge(with: startMonitoringAccountLockersEffect())
				.merge(with: gatewayValuesEffect())
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

	private func startMonitoringSecurityCenterEffect() -> Effect<Action> {
		.run { _ in
			do {
				try await securityCenterClient.startMonitoring()
			} catch {
				loggerGlobal.notice("securityCenterClient.startMonitoring failed: \(error)")
			}
		}
	}

	private func startMonitoringAccountLockersEffect() -> Effect<Action> {
		.run { _ in
			do {
				try await accountLockersClient.startMonitoring()
			} catch {
				loggerGlobal.notice("accountLockersClient.startMonitoring failed: \(error)")
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
