
extension ErrorQueue: DependencyKey {
	public typealias Value = ErrorQueue

	public static var liveValue: Self {
		let errors = AsyncPassthroughSubject<Error>()
		return Self(
			errors: { errors.share().eraseToAnyAsyncSequence() },
			schedule: { error in

				if error is CancellationError {
					loggerGlobal.warning("Suppressed `CancellationError`, i.e. preventing scheduling of this error on the ErrorQueue")
					return
				}

				if
					case let nsError = error as NSError,
					nsError.domain == NSURLErrorDomain,
					nsError.code == NSURLErrorCancelled
				{
					loggerGlobal.warning("Suppressed NSError with domain `NSURLErrorDomain`, i.e. preventing scheduling of this error on the ErrorQueue. \nDetails: code: \(nsError.code) - description: \"\(nsError.localizedDescription)\"")
					return
				}

				if !_XCTIsTesting {
					// easy to think a test failed if we print this warning during tests.
					loggerGlobal.error("An error occurred: \(String(describing: error))")
				}

				errors.send(error)
			}
		)
	}
}
