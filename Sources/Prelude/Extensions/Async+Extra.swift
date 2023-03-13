extension AsyncSequence {
	/// Waits and returns the first element from the seqeunce
	public func first() async throws -> Element {
		for try await element in self.prefix(1) {
			return element
		}
		throw CancellationError()
	}
}

public func doAsync<Result: Sendable>(
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

// MARK: - TimeoutError
public struct TimeoutError: Error {}
