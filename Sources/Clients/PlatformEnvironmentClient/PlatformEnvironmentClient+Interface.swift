import Foundation

public struct PlatformEnvironmentClient: Sendable {
	public typealias IsSimulator = @Sendable () -> Bool
	public var isSimulator: IsSimulator

	public init(isSimulator: @escaping IsSimulator) {
		self.isSimulator = isSimulator
	}
}
