import Foundation

// MARK: - EquatableVoid
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<EquatableVoid>`.
public struct EquatableVoid: Sendable, Equatable {
	public init() {}
}

extension TaskResult where Success == EquatableVoid {
	public init(catching body: @Sendable () async throws -> Void) async {
		do {
			try await body()
			self = .success(EquatableVoid())
		} catch {
			self = .failure(error)
		}
	}
}
