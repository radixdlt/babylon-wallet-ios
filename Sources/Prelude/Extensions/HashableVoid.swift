import Foundation

// MARK: - HashableVoid
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<HashableVoid>`.
public struct HashableVoid: Sendable, Hashable, Codable {
	public init() {}
}
