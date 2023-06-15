import Foundation

// MARK: - EquatableHashable
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<EquatableHashable>`.
public struct EquatableHashable: Sendable, Hashable, Codable {
	public init() {}
}
