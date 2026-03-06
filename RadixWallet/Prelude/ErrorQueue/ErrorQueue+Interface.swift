
struct ErrorQueue {
	var errors: @Sendable () -> AnyAsyncSequence<Error>
	var schedule: @Sendable (Error) -> Void
}
