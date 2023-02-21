import Prelude

// MARK: - TXVersionTag
public enum TXVersionTag: Sendable {}

/// Transaction Version
public typealias TXVersion = Tagged<TXVersionTag, UInt8>

extension TXVersion {
	public static let `default`: Self = 1
}
