import AsyncAlgorithms
import Foundation

public struct ErrorQueue {
	public var errors: @Sendable () -> AsyncChannel<Error>
	public var schedule: @Sendable (Error) -> Void
}
