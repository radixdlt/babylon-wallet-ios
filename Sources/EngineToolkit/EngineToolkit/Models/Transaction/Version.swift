import Foundation
import Tagged

// MARK: - VersionTag
public enum VersionTag: Sendable {}

/// Transaction Version
public typealias Version = Tagged<VersionTag, UInt8>

public extension Version {
	static let `default`: Self = 1
}
