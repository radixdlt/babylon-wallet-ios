import Foundation

extension PlatformEnvironmentClient {
        static let liveValue: Self = {
           Self(
                isSimulator: {
                        #if targetEnvironment(simulator)
                        return true
                        #else
                        return false
                        #endif
                }
           )
        }()
}
