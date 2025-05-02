import ComposableArchitecture
import SwiftUI

// MARK: - SceneDelegate
final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	@Dependency(\.bootstrapClient) var bootstrapClient
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
			bootstrapClient.configureSceneDelegate(SceneDelegateManager(sceneDelegate: self))
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

		self.statusOverlayWindow = overlayWindow
	}

	func setOverlayWindowInteractionEnabled(_ isEnabled: Bool) {
		self.statusOverlayWindow?.isUserInteractionEnabled = isEnabled
		self.contentOverlayWindow?.isUserInteractionEnabled = isEnabled
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
		biometricsSplashWindow?.windowLevel = .normal + 3
		biometricsSplashWindow?.makeKeyAndVisible()
	}

	func hideBiometricsSplashWindow() {
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

	@MainActor
	func hidePrivacyProtectionWindow() {
		privacyProtectionWindow?.isHidden = true
		privacyProtectionWindow = nil
	}
}

// MARK: - SceneDelegateManager
actor SceneDelegateManager {
	@Dependency(\.localAuthenticationClient) var localAuthenticationClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	let sceneDelegate: SceneDelegate

	init(sceneDelegate: SceneDelegate) {
		self.sceneDelegate = sceneDelegate
	}

	nonisolated func bootstrap() {
		Task {
			for try await _ in await localAuthenticationClient.authenticatedSuccessfully() {
				await hideBiometricsSplashWindow()
			}
		}

		Task {
			for try await isUserInteractionEnabled in await overlayWindowClient.isStatusUserInteractionEnabled() {
				await setOverlayWindowInteractionEnabled(isUserInteractionEnabled)
			}
		}
	}

	func hideBiometricsSplashWindow() async {
		await sceneDelegate.hideBiometricsSplashWindow()
	}

	func hidePrivacyProtectionWindow() async {
		await sceneDelegate.hidePrivacyProtectionWindow()
	}

	func setOverlayWindowInteractionEnabled(_ isEnabled: Bool) async {
		await sceneDelegate.setOverlayWindowInteractionEnabled(isEnabled)
	}
}
