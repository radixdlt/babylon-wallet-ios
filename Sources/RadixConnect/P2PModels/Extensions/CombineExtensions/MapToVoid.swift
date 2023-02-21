import Combine
import Foundation

extension Publisher {
	public func mapToVoid() -> AnyPublisher<Void, Failure> {
		map { _ in }.eraseToAnyPublisher()
	}
}
