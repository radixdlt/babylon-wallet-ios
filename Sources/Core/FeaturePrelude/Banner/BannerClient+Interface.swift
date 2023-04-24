import Dependencies
import UIKit

// MARK: - BannerClient
@MainActor
public struct BannerClient {
	public var setWindowScene: SetWindowScene
	public var presentBanner: PresentBanner
	static var scene: UIWindowScene?
	static var window: UIWindow?
}

extension BannerClient {
	public typealias SetWindowScene = (UIWindowScene) async -> Void
	public typealias PresentBanner = (String) async -> Void
}

extension DependencyValues {
	public var bannerClient: BannerClient {
		get { self[BannerClient.self] }
		set { self[BannerClient.self] = newValue }
	}
}
