import ComposableArchitecture
import SwiftUI

// MARK: - App
public struct App: Sendable, FeatureReducer {
	public struct State: Hashable {
		@CasePathable
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

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case task
		case urlOpened(URL)
	}

	@CasePathable
	public enum InternalAction: Sendable, Equatable {
		case incompatibleProfileDeleted
		case toMain(isAccountRecoveryNeeded: Bool)
		case toOnboarding
		case didResetWallet
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case main(Main.Action)
		case onboardingCoordinator(OnboardingCoordinator.Action)
		case splash(Splash.Action)
	}

	@Dependency(\.continuousClock) var clock
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.deepLinkHandlerClient) var deepLinkHandlerClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.homeCardsClient) var homeCardsClient
	@Dependency(\.appEventsClient) var appEventsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: \.child) {
			Scope(state: \.main, action: \.main) {
				Main()
			}
			Scope(state: \.onboardingCoordinator, action: \.onboardingCoordinator) {
				OnboardingCoordinator()
			}
			Scope(state: \.splash, action: \.splash) {
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
				deepLinkHandlerClient.setDeepLink(url)
				deepLinkHandlerClient.handleDeepLink()
			case .splash:
				deepLinkHandlerClient.setDeepLink(url)
			case .onboardingCoordinator:
				deepLinkHandlerClient.setDeepLink(url)
				presentDeepLinkNoProfileDialog()
			}
			return .none
		case .task:
			appEventsClient.handleEvent(.appStarted)
			return walletDidResetEffect()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .incompatibleProfileDeleted:
			goToOnboarding(state: &state)

		case .toMain:
			goToMain(state: &state)

		case .toOnboarding, .didResetWallet:
			goToOnboarding(state: &state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .onboardingCoordinator(.delegate(.completed)):
			return goToMain(state: &state)

		case let .splash(.delegate(.completed(profileState))):
			switch profileState {
			case .none:
				return goToOnboarding(state: &state)
			case let .incompatible(error):
				errorQueue.schedule(error)
				return goToOnboarding(state: &state)
			case let .loaded(profile):
				if profile.networks.isEmpty {
					return goToOnboarding(state: &state)
				}
				return goToMain(state: &state)
			}

		default:
			return .none
		}
	}

	private func goToMain(state: inout State) -> Effect<Action> {
		state.root = .main(.init(
			home: .init())
		)
		return .none
	}

	private func goToOnboarding(state: inout State) -> Effect<Action> {
		state.root = .onboardingCoordinator(.init())
		if deepLinkHandlerClient.hasDeepLink() {
			presentDeepLinkNoProfileDialog()
		}
		return .none
	}

	private func walletDidResetEffect() -> Effect<Action> {
		.run { send in
			do {
				for try await _ in appEventsClient.walletDidReset() {
					guard !Task.isCancelled else { return }
					await send(.internal(.didResetWallet))
				}
			} catch {
				loggerGlobal.error("Failed to iterate over walletDidReset: \(error)")
			}
		}
	}

	private func presentDeepLinkNoProfileDialog() {
		overlayWindowClient.scheduleAlertAndIgnoreAction(
			.init(
				title: { TextState(L10n.MobileConnect.NoProfileDialog.title) },
				message: { TextState(L10n.MobileConnect.NoProfileDialog.subtitle) }
			)
		)
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

private extension AppEventsClient {
	func walletDidReset() -> AnyAsyncSequence<AppEvent> {
		events()
			.filter { $0 == .walletDidReset }
			.eraseToAnyAsyncSequence()
	}
}
