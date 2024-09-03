import ComposableArchitecture
import SwiftUI

public final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	public weak var windowScene: UIWindowScene?
	public var overlayWindow: UIWindow?
	private var didEnterInBackground = false

	public func scene(
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
			overlayWindow(in: windowScene)
		}
	}

	public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		@Dependency(\.appsFlyerClient) var appsFlyerClient
		appsFlyerClient.continue(userActivity)
	}

	public func sceneWillEnterForeground(_ scene: UIScene) {
		guard didEnterInBackground, let scene = scene as? UIWindowScene else { return }

		if #unavailable(iOS 18) {
			showBiometricsSplashWindow(in: scene)
		}
		hidePrivacyProtectionWindow()
	}

	public func sceneDidEnterBackground(_ scene: UIScene) {
		guard let scene = scene as? UIWindowScene else { return }

		didEnterInBackground = true

		if #unavailable(iOS 18) {
			hideBiometricsSplashWindow()
		}
		showPrivacyProtectionWindow(in: scene)
	}

	// MARK: Overlay

	func overlayWindow(in scene: UIWindowScene) {
		let overlayView = OverlayReducer.View(
			store: .init(
				initialState: .init(),
				reducer: OverlayReducer.init
			))

		let overlayWindow = UIWindow(windowScene: scene)
		overlayWindow.rootViewController = UIHostingController(rootView: overlayView)
		overlayWindow.rootViewController?.view.backgroundColor = .clear
		overlayWindow.windowLevel = .normal + 1
		overlayWindow.isUserInteractionEnabled = false
		overlayWindow.makeKeyAndVisible()

		@Dependency(\.overlayWindowClient) var overlayWindowClient
		Task { @MainActor [overlayWindow] in
			for try await isUserInteractionEnabled in overlayWindowClient.isUserInteractionEnabled() {
				overlayWindow.isUserInteractionEnabled = isUserInteractionEnabled
			}
		}

		self.overlayWindow = overlayWindow
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

		@Dependency(\.localAuthenticationClient) var localAuthenticationClient
		Task { @MainActor in
			for try await _ in localAuthenticationClient.authenticatedSuccessfully() {
				hideBiometricsSplashWindow()
			}
		}
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
