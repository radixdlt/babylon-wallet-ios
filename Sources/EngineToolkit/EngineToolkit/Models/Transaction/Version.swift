import Foundation
import Tagged

// MARK: - TXVersionTag
public enum TXVersionTag: Sendable {}

/// Transaction Version
public typealias TXVersion = Tagged<TXVersionTag, UInt8>

public extension TXVersion {
	static let `default`: Self = 1
}
