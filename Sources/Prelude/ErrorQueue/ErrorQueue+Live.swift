import AsyncAlgorithms
import Dependencies

extension ErrorQueue: DependencyKey {
	public typealias Value = ErrorQueue

	public static var liveValue: Self {
		let errorChannel = AsyncChannel<Error>()
		return Self(
			errors: { errorChannel.eraseToAnyAsyncSequence() },
			schedule: { error in
				if !_XCTIsTesting {
					// easy to think a test failed if we print this warning during tests.
					loggerGlobal.error("An error occurred: \(String(describing: error))")
				}
				Task {
					await errorChannel.send(error)
				}
			}
		)
	}
}
