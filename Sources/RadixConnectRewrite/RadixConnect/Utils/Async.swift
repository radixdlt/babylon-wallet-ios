import AsyncExtensions
import Prelude

// MARK: - AnyAsyncIterator + Sendable
extension AnyAsyncIterator: @unchecked Sendable where Self.Element: Sendable {}

// MARK: - AnyAsyncSequence + Sendable
extension AnyAsyncSequence: @unchecked Sendable where Self.AsyncIterator: Sendable {}

extension AsyncSequence {
	func mapSkippingError<NewValue: Sendable>(
		_ f: @Sendable @escaping (Element) async throws -> NewValue,
		logError: @Sendable @escaping (Error) -> Void = { _ in }
	) -> AnyAsyncSequence<NewValue> where Element: Sendable, Self: Sendable {
		compactMap { element in
			do {
				return try await f(element)
			} catch {
				logError(error)
				return nil
			}
		}.eraseToAnyAsyncSequence()
	}
}

extension AsyncSequence {
	func logInfo(
		_ message: String
	) -> AnyAsyncSequence<Element> where Element: Sendable, Self: Sendable {
		handleEvents(onElement: { element in
			loggerGlobal.info(.init(stringLiteral: String(format: message, "\(dump(element))")))
		}).eraseToAnyAsyncSequence()
	}
}

extension AsyncSequence where Element == Void {
	func await(inGroup group: inout ThrowingTaskGroup<Void, Error>) where Self: Sendable {
		_ = group.addTaskUnlessCancelled {
			try Task.checkCancellation()
			for try await _ in self {
				guard !Task.isCancelled else { return }
			}
		}
	}
}
