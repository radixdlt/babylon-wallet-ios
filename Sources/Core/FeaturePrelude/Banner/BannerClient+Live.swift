import Dependencies
import UIKit
import SwiftUI
import AsyncExtensions

extension BannerClient: DependencyKey {
        public static let liveValue: Self = {
                let bannerChannel = AsyncPassthroughSubject<Banner>()
                return .init(
                        events: { bannerChannel.eraseToAnyAsyncSequence() },
                        scheduleAlert: {
                                bannerChannel.send(.alert($0))
                        },
                        scheduleHUD: {
                                bannerChannel.send(.hud($0))
                        }
                )
        }()
}
