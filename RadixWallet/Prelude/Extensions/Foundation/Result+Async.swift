
extension Result {
	func asyncFlatMap<NewSuccess: Sendable>(
		transform: (Success) async -> Result<NewSuccess, Failure>
	) async -> Result<NewSuccess, Failure> {
		switch self {
		case let .success(success):
			await transform(success)
		case let .failure(failure):
			.failure(failure)
		}
	}
}
