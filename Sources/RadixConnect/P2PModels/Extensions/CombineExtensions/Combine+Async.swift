import Combine
import Foundation

extension Publisher {
	public func async() async throws -> Output {
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
}
