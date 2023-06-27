import UIKit

public final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	public weak var windowScene: UIWindowScene?
        public var overlayWindow: UIWindow?

	public func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		windowScene = scene as? UIWindowScene
                if let windowScene {
                        overlayWindow(in: windowScene)
                }
	}

        func overlayWindow(in scene: UIWindowScene) {
                let overlayWindow = UIWindow(windowScene: scene)
                overlayWindow.windowLevel = .normal + 1
                overlayWindow.isUserInteractionEnabled = false
                overlayWindow.makeKeyAndVisible()

                self.overlayWindow = overlayWindow
        }
}
