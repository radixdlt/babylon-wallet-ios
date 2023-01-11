import Combine
import Foundation

public extension Publisher {
	func async() async throws -> Output {
		try await withCheckedThrowingContinuation { continuation in
			var cancellable: AnyCancellable?
			var finishedWithoutValue = true
			cancellable = first()
				.sink { result in
					switch result {
					case .finished:
						if finishedWithoutValue {
							continuation.resume(throwing: ConverseError.shared(.publisherFinishedWithoutValue))
						}
					case let .failure(error):
						continuation.resume(throwing: error)
					}
					cancellable?.cancel()
				} receiveValue: { value in
					finishedWithoutValue = false
					continuation.resume(with: .success(value))
				}
		}
	}

	func asyncMap<T>(
		_ transform: @escaping (Output) async throws -> T
	) -> Publishers.FlatMap<Future<T, Error>,
		Publishers.SetFailureType<Self, Error>>
	{
		flatMap { value in
			Future { promise in
				Task {
					do {
						let output = try await transform(value)
						promise(.success(output))
					} catch {
						promise(.failure(error))
					}
				}
			}
		}
	}
}
