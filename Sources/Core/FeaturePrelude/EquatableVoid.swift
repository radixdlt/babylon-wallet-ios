import ComposableArchitecture
import Foundation

// MARK: - EquatableVoid
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<EquatableVoid>`.
public struct EquatableVoid: Sendable, Equatable {
	public init() {}
}

public extension TaskResult where Success == EquatableVoid {
	init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(EquatableVoid())
		} catch {
			self = .failure(error)
		}
	}
}
