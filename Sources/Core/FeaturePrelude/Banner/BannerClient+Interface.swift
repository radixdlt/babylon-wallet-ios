import Dependencies
import UIKit
import AsyncExtensions
import Resources
import ComposableArchitecture
import SwiftUI

// MARK: - BannerClient
public struct BannerClient {
        public enum Banner: Sendable, Hashable {
                public typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
                public enum AlertAction: Equatable {
                        case primaryButtonTapped
                }

                public struct HUD: Sendable, Hashable {
                        public enum Icon: Sendable, Hashable {
                                case asset(ImageAsset)
                                case system(String)
                        }
                        public let text: String
                        public let icon: Icon?
                        public let iconForegroundColor: Color?

                        public init(text: String, icon: Icon?, iconForegroundColor: Color?) {
                                self.text = text
                                self.icon = icon
                                self.iconForegroundColor = iconForegroundColor
                        }
                }

                case hud(HUD)
                case alert(AlertState)
        }

        public var events: Events
        public var scheduleAlert: ScheduleAlert
        public var scheduleHUD: ScheduleHUD
}

extension ImageAsset: Hashable {
        public func hash(into hasher: inout Hasher) {
                hasher.combine(self.name)
        }
}

extension BannerClient {
        public typealias ScheduleAlert = @Sendable (Banner.AlertState) -> Void

        public typealias ScheduleHUD = @Sendable (Banner.HUD) -> Void

	public typealias Events = @Sendable () -> AnyAsyncSequence<Banner>
}

extension BannerClient {
        public func schedule(userError error: Error) {
                scheduleAlert(.init(
                        title: { TextState(L10n.Common.errorAlertTitle) },
                        message: { TextState(error.localizedDescription) }
                ))
        }

        public func schedule(userInfo info: String) {
                scheduleHUD(.init(text: info, icon: .system("checkmark.circle.fill"), iconForegroundColor: .app.green1))
        }
}

extension DependencyValues {
	public var bannerClient: BannerClient {
		get { self[BannerClient.self] }
		set { self[BannerClient.self] = newValue }
	}
}
