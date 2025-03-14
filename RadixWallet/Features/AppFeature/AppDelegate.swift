import ComposableArchitecture
import SwiftUI

// MARK: - AppDelegate
final class AppDelegate: NSObject, UIApplicationDelegate {
	@Dependency(\.bootstrapClient) var bootstrapClient
	@Dependency(\.appsFlyerClient) var appsFlyerClient

	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
		sceneConfig.delegateClass = SceneDelegate.self
		return sceneConfig
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		bootstrapClient.bootstrap()
		return true
	}

	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
		appsFlyerClient.continue(userActivity)
		return true
	}
}
