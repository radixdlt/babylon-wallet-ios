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
	@Dependency(\.resetWalletClient) var resetWalletClient

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
				// FIXME: Strings
				overlayWindowClient.scheduleAlertAndIgnoreAction(.init(title: { TextState("dApp Request") }, message: {
					TextState("You can proceed with this request after you create or restore your Radix Wallet.")
				}))
			}
			return .none
		case .task:
			return didResetWalletEffect()
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

	private func goToMain(state: inout State) -> Effect<Action> {
		state.root = .main(.init(
			home: .init())
		)

		// At fresh app start, handle deepLink only when app goes to main state.
		// While splash screen is shown, or during the onboarding, the deepLink is buffered.
		deepLinkHandlerClient.handleDeepLink()
		return .none
	}

	private func goToOnboarding(state: inout State) -> Effect<Action> {
		state.root = .onboardingCoordinator(.init())
		if deepLinkHandlerClient.hasDeepLink() {
			// FIXME: Strings
			overlayWindowClient.scheduleAlertAndIgnoreAction(.init(title: { TextState("dApp Request") }, message: {
				TextState("You can proceed with this request after you create or restore your Radix Wallet.")
			}))
		}
		return .none
	}

	private func didResetWalletEffect() -> Effect<Action> {
		.run { send in
			do {
				for try await _ in resetWalletClient.walletDidReset() {
					guard !Task.isCancelled else { return }
					await send(.internal(.didResetWallet))
				}
			} catch {
				loggerGlobal.error("Failed to iterate over walletDidReset: \(error)")
			}
		}
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
