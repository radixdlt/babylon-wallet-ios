import ComposableArchitecture
import SwiftUI

// MARK: - App
public struct App: Sendable, FeatureReducer {
	public struct State: Hashable {
		public enum Root: Hashable {
			case main(Main.State)
			case onboardingCoordinator(OnboardingCoordinator.State)
			case splash(Splash.State)
		}

		public var root: Root

		public init(
			root: Root = .splash(.init())
		) {
			self.root = root
			let retBuildInfo = buildInformation()
			loggerGlobal.info("App started - engineToolkit commit hash: \(retBuildInfo.version)")
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
	}

	public enum InternalAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case toMain(isAccountRecoveryNeeded: Bool)
		case toOnboarding
	}

	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.main, action: /ChildAction.main) {
					Main()
				}
				.ifCaseLet(/State.Root.onboardingCoordinator, action: /ChildAction.onboardingCoordinator) {
					OnboardingCoordinator()
				}
				.ifCaseLet(/State.Root.splash, action: /ChildAction.splash) {
					Splash()
				}
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { _ in
				for try await deviceConflict in await onboardingClient.conflictingDeviceUsages() {
					guard !Task.isCancelled else { return }
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .incompatibleProfileDeleted:
			goToOnboarding(state: &state)

		case let .toMain(isAccountRecoveryNeeded):
			goToMain(state: &state, accountRecoveryIsNeeded: isAccountRecoveryNeeded)

		case .toOnboarding:
			goToOnboarding(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .main(.delegate(.removedWallet)):
			goToOnboarding(state: &state)

		case .onboardingCoordinator(.delegate(.completed)):
			goToMain(state: &state, accountRecoveryIsNeeded: false)

		case let .splash(.delegate(.completed(profile, accountRecoveryNeeded))):
			if profile.hasMainnetAccounts() {
				goToMain(state: &state, accountRecoveryIsNeeded: accountRecoveryNeeded)
			} else {
				goToOnboarding(state: &state)
			}
		default:
			.none
		}
	}

	func goToMain(state: inout State, accountRecoveryIsNeeded: Bool) -> Effect<Action> {
		state.root = .main(.init(
			home: .init(
				babylonAccountRecoveryIsNeeded: accountRecoveryIsNeeded
			))
		)
		return .none
	}

	func goToOnboarding(state: inout State) -> Effect<Action> {
		state.root = .onboardingCoordinator(.init())
		return .none
	}
}

// MARK: App.UserFacingError
extension App {
	/// A purely user-facing error. Not made for developer logging or analytics collection.
	public struct UserFacingError: Sendable, Equatable, LocalizedError {
		let underlyingError: Swift.Error

		init(_ underlyingError: Swift.Error) {
			self.underlyingError = underlyingError
		}

		public var errorDescription: String? {
			underlyingError.legibleLocalizedDescription
		}

		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.underlyingError.localizedDescription == rhs.underlyingError.localizedDescription
		}
	}
}
