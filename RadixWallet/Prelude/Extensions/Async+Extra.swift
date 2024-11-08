extension AsyncSequence {
	/// Waits and returns the first element from the seqeunce
	func first() async throws -> Element {
		for try await element in self.prefix(1) {
			return element
		}
		throw CancellationError()
	}
}

func doAsync<Result: Sendable>(
	withTimeout duration: Duration,
	clock: some Clock<Duration> = ContinuousClock(),
	work: @Sendable @escaping () async throws -> Result
) async throws -> Result {
	try await withThrowingTaskGroup(of: Result.self) { group in
		_ = group.addTaskUnlessCancelled {
			try await clock.sleep(for: duration)
			try Task.checkCancellation()

			throw TimeoutError()
		}

		_ = group.addTaskUnlessCancelled {
			try await work()
		}

		let result = try await group.first()
		group.cancelAll()
		return result
	}
}

extension Collection where Element: Sendable {
	func parallelMap<T: Sendable>(_ transform: @Sendable @escaping (Element) async throws -> T) async throws -> [T] {
		try await withThrowingTaskGroup(of: T.self) { group in
			for element in self {
				_ = group.addTaskUnlessCancelled {
					try await transform(element)
				}
			}
			return try await group.collect()
		}
	}

	func parallelMap<T: Sendable>(_ transform: @Sendable @escaping (Element) async -> T) async -> [T] {
		await withTaskGroup(of: T.self) { group in
			for element in self {
				_ = group.addTaskUnlessCancelled {
					await transform(element)
				}
			}
			return await group.collect()
		}
	}
}

extension AsyncSequence {
	func subscribe(
		_ continuation: AsyncStream<Element>.Continuation
	) where Self: Sendable {
		Task {
			for try await value in self {
				continuation.yield(value)
			}
		}
	}
}

extension AsyncSequence {
	func subscribe(_ listener: some AsyncSubjectable<Element>) where Self: Sendable {
		Task {
			for try await value in self {
				listener.send(value)
			}
		}
	}
}

// MARK: - TimeoutError
struct TimeoutError: Error {}
