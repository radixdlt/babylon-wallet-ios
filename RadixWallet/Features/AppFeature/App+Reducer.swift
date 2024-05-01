import ComposableArchitecture
import SwiftUI

// MARK: - App
public struct App: Sendable, FeatureReducer {
	public struct State: Hashable {
		public enum Root: Hashable {
			case main(Main.State)
			case onboardingCoordinator(OnboardingCoordinator.State)
			case splash(Splash.State)

			var isMain: Bool {
				if case .main = self {
					return true
				}
				return false
			}
		}

		public var root: Root
		public var deferredDeepLink: URL?

		public init(
			root: Root = .splash(.init())
		) {
			self.root = root
			let sargonBuildInfo = SargonBuildInformation.get()
			let config = BuildConfiguration.current?.description ?? "Unknown Build Config"
			loggerGlobal.info("App started (\(config), Sargon=\(sargonBuildInfo))")
		}
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

	public enum ViewAction: Sendable, Equatable {
		case urlOpened(URL)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.deepLinkHandlerClient) var deepLinkHandlerClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient

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
		case let .urlOpened(url):
			switch state.root {
			case .main:
				deepLinkHandlerClient.addDeepLink(url)
				deepLinkHandlerClient.handleDeepLink()
			case .splash:
				deepLinkHandlerClient.addDeepLink(url)
			case .onboardingCoordinator:
				deepLinkHandlerClient.addDeepLink(url)
				overlayWindowClient.scheduleAlertIgnoreAction(.init(title: { TextState("dApp Request") }, message: {
					TextState("You will be able to handle dApp request after creating a profile")
				}))
			}
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .incompatibleProfileDeleted:
			goToOnboarding(state: &state)

		case .toMain:
			goToMain(state: &state)

		case .toOnboarding:
			goToOnboarding(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .main(.delegate(.removedWallet)):
			goToOnboarding(state: &state)

		case .onboardingCoordinator(.delegate(.completed)):
			goToMain(state: &state)

		case let .splash(.delegate(.completed(profile))):
			if profile.networks.isEmpty {
				goToOnboarding(state: &state)
			} else {
				goToMain(state: &state)
			}
		default:
			.none
		}
	}

	func goToMain(state: inout State) -> Effect<Action> {
		state.root = .main(.init(
			home: .init())
		)

		deepLinkHandlerClient.handleDeepLink()
		return .none
	}

	func goToOnboarding(state: inout State) -> Effect<Action> {
		state.root = .onboardingCoordinator(.init())
		if deepLinkHandlerClient.hasDeepLink() {
			overlayWindowClient.scheduleAlertIgnoreAction(.init(title: { TextState("dApp Request") }, message: {
				TextState("You will be able to handle dApp request after creating a profile")
			}))
		}
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
