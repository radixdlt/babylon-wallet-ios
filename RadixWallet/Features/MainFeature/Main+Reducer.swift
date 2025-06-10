import ComposableArchitecture
import SwiftUI

struct Main: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		// MARK: - Components
		var home: Home.State
		var dAppsDirectory: DAppsDirectory.State
		var discover: Discover.State
		var settings: Settings.State

		var isOnMainnet = true

		// MARK: - Destination
		@PresentationState
		var destination: Destination.State?
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case dAppsDirectory(DAppsDirectory.Action)
		case discover(Discover.Action)
		case settings(Settings.Action)
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Gateway)
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
		Scope(state: \.dAppsDirectory, action: \.child.dAppsDirectory) {
			DAppsDirectory()
		}
		Scope(state: \.discover, action: \.child.discover) {
			Discover()
		}
		Scope(state: \.settings, action: \.child.settings) {
			Settings()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .currentGatewayChanged(currentGateway):
			state.isOnMainnet = currentGateway.network.id == .mainnet
			return .none
		}
	}
}
