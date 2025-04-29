import ComposableArchitecture
import FirebaseCrashlytics
import SwiftUI

struct Main: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		// MARK: - Components
		var home: Home.State

		var isOnMainnet = true

		// MARK: - Destination
		@PresentationState
		var destination: Destination.State?

		init(home: Home.State) {
			self.home = home
		}
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Gateway)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case settings(Settings.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case settings(Settings.Action)
		}

		var body: some ReducerOf<Self> {
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
	@Dependency(\.radixConnectClient) var radixConnectClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.home, action: \.child.home) {
			Home()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			Crashlytics.crashlytics().log("Main view task started")
			// At fresh app start, handle deepLink only when app goes to main state.
			// While splash screen is shown, or during the onboarding, the deepLink is buffered.
			deepLinkHandlerClient.handleDeepLink()

			return startAutomaticBackupsEffect()
				.merge(with: startMonitoringSecurityCenterEffect())
				.merge(with: startMonitoringAccountLockersEffect())
				.merge(with: gatewayValuesEffect())
				.merge(with: startNotifyingConnectorWithAccounts())
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

	private func startNotifyingConnectorWithAccounts() -> Effect<Action> {
		.run { _ in
			do {
				try await radixConnectClient.startNotifyingConnectorWithAccounts()
			} catch {
				loggerGlobal.notice("radixConnectClient.startNotifyingConnectorWithAccounts failed: \(error)")
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .currentGatewayChanged(currentGateway):
			state.isOnMainnet = currentGateway.network.id == .mainnet
			return .none
		}
	}
}
