import ComposableArchitecture
import SwiftUI

public final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	public weak var windowScene: UIWindowScene?
	public var overlayWindow: UIWindow?

	@Dependency(\.radixConnectClient) var radixConnectionClient

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

		loggerGlobal.error("has urlContext: \(connectionOptions.urlContexts)")
		if let connectURL = connectionOptions.urlContexts.first?.url {
			let connectionPassword = URLComponents(url: connectURL, resolvingAgainstBaseURL: true)?.queryItems?.first?.value
			if let connectionPassword {
				let cp = try! ConnectionPassword(.init(hex: connectionPassword))
				Task {
					try await radixConnectionClient.handleDappDeepLink(cp)
				}
			}
		}
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

	public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		let connectionPassword = URLComponents(url: URLContexts.first!.url, resolvingAgainstBaseURL: true)?.queryItems?.first?.value
		loggerGlobal.error("has urlContext: \(connectionPassword)")
		if let connectionPassword {
			let cp = try! ConnectionPassword(.init(hex: connectionPassword))
			Task {
				try await radixConnectionClient.handleDappDeepLink(cp)
			}
//			Task {
//				try await radixConnectionClient.addP2PWithPassword(ConnectionPassword(.init(hex: connectionPassword)))
//			}
		}
	}
}
