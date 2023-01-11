import Prelude

extension ErrorQueue: DependencyKey {
	public typealias Value = ErrorQueue

	public static var liveValue: Self {
		let errorChannel = AsyncChannel<Error>()
		return Self(
			errors: { errorChannel.eraseToAnyAsyncSequence() },
			schedule: { error in
				Task {
					await errorChannel.send(error)
				}
			}
		)
	}
}
