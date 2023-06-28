import AsyncAlgorithms
import Dependencies

extension ErrorQueue: DependencyKey {
	public typealias Value = ErrorQueue

	public static var liveValue: Self {
		let errors = AsyncPassthroughSubject<Error>()
		return Self(
			errors: { errors.share().eraseToAnyAsyncSequence() },
			schedule: { error in
				if !_XCTIsTesting {
					// easy to think a test failed if we print this warning during tests.
					loggerGlobal.error("An error occurred: \(String(describing: error))")
				}

				errors.send(error)
			}
		)
	}
}
