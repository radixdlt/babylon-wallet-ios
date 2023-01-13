import AsyncExtensions

public struct ErrorQueue: Sendable {
	public var errors: @Sendable () -> AnyAsyncSequence<Error>
	public var schedule: @Sendable (Error) -> Void
}
