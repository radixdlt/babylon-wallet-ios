
struct ErrorQueue: Sendable {
	var errors: @Sendable () -> AnyAsyncSequence<Error>
	var schedule: @Sendable (Error) -> Void
}
