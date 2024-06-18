import AppsFlyerLib
import ComposableArchitecture
import SwiftUI

// MARK: - AppDelegate
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

	public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		@Dependency(\.appsFlyerClient) var appsFlyerClient

		AppsFlyerLib.shared().delegate = self
		AppsFlyerLib.shared().deepLinkDelegate = self

		appsFlyerClient.start()

		return true
	}

	public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
		DebugInfo.shared.add("AppsFlyerLib.continue called")
		AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
		return true
	}

	public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
		DebugInfo.shared.add("AppsFlyierLib.handleOpen called \(url.absoluteString)")
		AppsFlyerLib.shared().handleOpen(url, options: options)
		return true
	}

	public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		DebugInfo.shared.add("AppsFlyierLib.handleOpen called \(url.absoluteString)")
		AppsFlyerLib.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
		return true
	}
}

// MARK: AppsFlyerLibDelegate
extension AppDelegate: AppsFlyerLibDelegate {
	public func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
		// Invoked when conversion data resolution succeeds
		DebugInfo.shared.add("onConversionDataSuccess \(conversionInfo)")
	}

	public func onConversionDataFail(_ error: any Error) {
		// Invoked when conversion data resolution fails
		DebugInfo.shared.add("onConversionDataFail")
	}
}

// MARK: DeepLinkDelegate
extension AppDelegate: DeepLinkDelegate {
	public func didResolveDeepLink(_ result: DeepLinkResult) {
		if let deepLink = result.deepLink {
			DebugInfo.shared.add("did resolve deep link: \(deepLink)\nClick events: \(deepLink.clickEvent)")
		} else if let error = result.error {
			DebugInfo.shared.add("fail to resolve deep link. Status: \(result.status), Error: \(error)")
		}
	}
}
