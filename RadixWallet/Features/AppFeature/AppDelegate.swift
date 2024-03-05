import ComposableArchitecture
import SwiftUI

public final class AppDelegate: NSObject, UIApplicationDelegate {
	public func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
		sceneConfig.delegateClass = SceneDelegate.self
		return sceneConfig
	}

	public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		true
	}

	public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
		true
	}
}
