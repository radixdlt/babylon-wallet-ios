import Foundation

// MARK: - Unit
/// Useful when writing features where actions semantically have associated value
/// `TaskResult<Void>` which does not compile since `Void` is not `Equatable`. We
/// can now use `TaskResult<Prelude.Unit>`.
public struct Unit: Sendable, Hashable, Codable {
	public init() {}
}
