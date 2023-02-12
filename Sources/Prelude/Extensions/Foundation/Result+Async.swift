import Foundation

extension Result {
	public func asyncFlatMap<NewSuccess: Sendable>(
		transform: (Success) async -> Result<NewSuccess, Failure>
	) async -> Result<NewSuccess, Failure> {
		switch self {
		case let .success(success):
			return await transform(success)
		case let .failure(failure):
			return .failure(failure)
		}
	}
}
