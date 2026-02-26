import ComposableArchitecture
import FirebaseCore
import FirebaseCrashlytics
import SwiftUI

// MARK: - AppDelegate
final class AppDelegate: NSObject, UIApplicationDelegate {
	@Dependency(\.bootstrapClient) var bootstrapClient
	@Dependency(\.userDefaults) var userDefaults

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
		configureFirebase()
		bootstrapClient.bootstrap()
		Crashlytics.crashlytics().log("Clients bootstrapped")
		return true
	}

	private func configureFirebase() {
		guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
		      let options = FirebaseOptions(contentsOfFile: filePath),
		      options.projectID != nil
		else {
			#if DEBUG
			print("Warning: Empty or missing GoogleService-Info.plist. Firebase not configured.")
			return
			#else
			fatalError("Missing valid GoogleService-Info.plist in Release build!")
			#endif
		}
		FirebaseApp.configure(options: options)
		Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(userDefaults.shareCrashReportsIsEnabled)
		Crashlytics.crashlytics().log("App started")
	}
}
