import Foundation

public struct PlatformEnvironmentClient {
        typealias IsSimulator = () -> Bool
        var isSimulator: IsSimulator

        init(isSimulator: @escaping IsSimulator) {
                self.isSimulator = isSimulator
        }
}
