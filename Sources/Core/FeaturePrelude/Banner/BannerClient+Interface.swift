import Dependencies
import UIKit

// MARK: - BannerClient
@MainActor
public struct BannerClient {
        public enum Banner: Sendable {
                case toast(String)
                case error(Error)
        }

	public var setWindowScene: SetWindowScene
	public var presentBanner: PresentBanner
        public var presentErorrAllert: PresentErrorAlert
        public var schedule: @Sendable (Banner) -> Void
	static var scene: UIWindowScene?
	static var window: UIWindow?
}

extension BannerClient {
	public typealias SetWindowScene = (UIWindowScene) async -> Void
	public typealias PresentBanner = (String) async -> Void
        public typealias PresentErrorAlert = (String) async -> Void
}

extension DependencyValues {
	public var bannerClient: BannerClient {
		get { self[BannerClient.self] }
		set { self[BannerClient.self] = newValue }
	}
}
