// MARK: - Either + Sendable
extension Either: @unchecked Sendable {}

extension Either {
	public func doAsync(
		ifLeft: (Left) async throws -> Void,
		ifRight: (Right) async throws -> Void
	) async rethrows {
		switch self {
		case let .left(left):
			try await ifLeft(left)
		case let .right(right):
			try await ifRight(right)
		}
	}
}
