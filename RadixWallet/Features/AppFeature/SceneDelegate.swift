import ComposableArchitecture
import SwiftUI

public final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	public weak var windowScene: UIWindowScene?
	public var overlayWindow: UIWindow?

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

	public func sceneWillResignActive(_ scene: UIScene) {
		guard let scene = scene as? UIWindowScene else { return }
		showPrivacyProtectionWindow(in: scene)
	}

	public func sceneDidBecomeActive(_ scene: UIScene) {
		guard let scene = scene as? UIWindowScene else { return }
		hidePrivacyProtectionWindow(in: scene)
	}

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

	// MARK: Privacy Protection

	private var privacyProtectionWindow: UIWindow?

	private func showPrivacyProtectionWindow(in scene: UIWindowScene) {
		privacyProtectionWindow = UIWindow(windowScene: scene)
		privacyProtectionWindow?.rootViewController = UIHostingController(rootView: SplashView())
		privacyProtectionWindow?.windowLevel = .statusBar + 1
		privacyProtectionWindow?.makeKeyAndVisible()
	}

	private func hidePrivacyProtectionWindow(in scene: UIWindowScene) {
		privacyProtectionWindow?.isHidden = true
		privacyProtectionWindow = nil
	}
}
