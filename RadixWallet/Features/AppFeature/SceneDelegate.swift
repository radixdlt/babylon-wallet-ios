import ComposableArchitecture
import SwiftUI

final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	weak var windowScene: UIWindowScene?
	private var didEnterBackground = false

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		windowScene = scene as? UIWindowScene
		if
			let windowScene,
			// avoids unimplemented("OverlayWindowClient.isUserInteractionEnabled")
			!_XCTIsTesting
		{
			contentOverlayWindow(in: windowScene)
			statusOverlayWindow(in: windowScene)
		}

		// avoids unimplemented("LocalAuthenticationClient.authenticatedSuccessfully")
		if !_XCTIsTesting {
			@Dependency(\.localAuthenticationClient) var localAuthenticationClient
			Task { @MainActor in
				for try await _ in localAuthenticationClient.authenticatedSuccessfully() {
					hideBiometricsSplashWindow()
				}
			}
		}
	}

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		@Dependency(\.appsFlyerClient) var appsFlyerClient
		appsFlyerClient.continue(userActivity)
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		guard didEnterBackground, let scene = scene as? UIWindowScene else { return }

		if #unavailable(iOS 18) {
			showBiometricsSplashWindow(in: scene)
		}
		hidePrivacyProtectionWindow()
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		guard let scene = scene as? UIWindowScene else { return }

		didEnterBackground = true

		if #unavailable(iOS 18) {
			hideBiometricsSplashWindow()
		}
		showPrivacyProtectionWindow(in: scene)
	}

	// MARK: Content Overlay

	private var contentOverlayWindow: UIWindow?

	func contentOverlayWindow(in scene: UIWindowScene) {
		let overlayView = ContentOverlay.View(
			store: .init(
				initialState: .init(),
				reducer: ContentOverlay.init
			))

		let overlayWindow = UIWindow(windowScene: scene)
		overlayWindow.rootViewController = UIHostingController(rootView: overlayView)
		overlayWindow.rootViewController?.view.backgroundColor = .clear
		overlayWindow.windowLevel = .normal + 1
		overlayWindow.isUserInteractionEnabled = false
		overlayWindow.makeKeyAndVisible()

		@Dependency(\.overlayWindowClient) var overlayWindowClient
		Task { @MainActor [overlayWindow] in
			for try await isUserInteractionEnabled in overlayWindowClient.isContentUserInteractionEnabled() {
				overlayWindow.isUserInteractionEnabled = isUserInteractionEnabled
			}
		}

		self.contentOverlayWindow = overlayWindow
	}

	// MARK: Status Overlay

	private var statusOverlayWindow: UIWindow?

	func statusOverlayWindow(in scene: UIWindowScene) {
		let overlayView = StatusOverlay.View(
			store: .init(
				initialState: .init(),
				reducer: StatusOverlay.init
			))

		let overlayWindow = UIWindow(windowScene: scene)
		overlayWindow.rootViewController = UIHostingController(rootView: overlayView)
		overlayWindow.rootViewController?.view.backgroundColor = .clear
		overlayWindow.windowLevel = .normal + 2
		overlayWindow.isUserInteractionEnabled = false
		overlayWindow.makeKeyAndVisible()

		@Dependency(\.overlayWindowClient) var overlayWindowClient
		Task { @MainActor [overlayWindow] in
			for try await isUserInteractionEnabled in overlayWindowClient.isStatusUserInteractionEnabled() {
				overlayWindow.isUserInteractionEnabled = isUserInteractionEnabled
			}
		}

		self.statusOverlayWindow = overlayWindow
	}

	// MARK: Biometrics

	private var biometricsSplashWindow: UIWindow?

	private func showBiometricsSplashWindow(in scene: UIWindowScene) {
		let splashView = Splash.View(
			store: .init(
				initialState: .init(context: .appForegrounded),
				reducer: Splash.init
			))

		biometricsSplashWindow = UIWindow(windowScene: scene)
		biometricsSplashWindow?.rootViewController = UIHostingController(rootView: splashView)
		biometricsSplashWindow?.windowLevel = .normal + 2
		biometricsSplashWindow?.makeKeyAndVisible()
	}

	private func hideBiometricsSplashWindow() {
		biometricsSplashWindow?.isHidden = true
		biometricsSplashWindow = nil
	}

	// MARK: Privacy Protection

	private var privacyProtectionWindow: UIWindow?

	private func showPrivacyProtectionWindow(in scene: UIWindowScene) {
		privacyProtectionWindow = UIWindow(windowScene: scene)
		privacyProtectionWindow?.rootViewController = UIHostingController(rootView: SplashView())
		privacyProtectionWindow?.windowLevel = .statusBar + 1
		privacyProtectionWindow?.makeKeyAndVisible()
	}

	private func hidePrivacyProtectionWindow() {
		privacyProtectionWindow?.isHidden = true
		privacyProtectionWindow = nil
	}
}
