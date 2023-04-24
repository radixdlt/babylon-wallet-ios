import Dependencies
import UIKit

extension BannerClient: DependencyKey {
	public static let liveValue: Self = .init(
		setWindowScene: { windowScene in
			scene = windowScene
		},
		presentBanner: { text in
			guard window == nil, let windowScene = scene else { return }
			window = UIWindow(windowScene: windowScene)
			guard let bannerWindow = window else { return }
			bannerWindow.rootViewController = BannerViewController(
				text: text,
				completed: {
					window = nil
				}
			)
			bannerWindow.windowLevel = .normal + 1
			bannerWindow.isUserInteractionEnabled = false
			bannerWindow.makeKeyAndVisible()
		}
	)
}
