import Prelude

// MARK: - EpochTag
public enum EpochTag: Sendable {}

/// Network Epoch
public typealias Epoch = Tagged<EpochTag, UInt64>
