import Foundation

public extension Sequence {
	func asyncMap<T>(
		_ transform: (Element) async throws -> T
	) async rethrows -> [T] {
		var values = [T]()

		for element in self {
			try await values.append(transform(element))
		}

		return values
	}
}

public extension Result {
	func asyncFlatMap<NewSuccess: Sendable>(
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
