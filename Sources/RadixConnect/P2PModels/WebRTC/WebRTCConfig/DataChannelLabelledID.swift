import Prelude

// MARK: - DataChannelLabelledID
public struct DataChannelLabelledID: Sendable, Hashable, Codable, CustomStringConvertible {
	public let channelId: DataChannelID
	public let channelLabel: DataChannelLabel

	public init(
		channelId: DataChannelID,
		channelLabel: DataChannelLabel
	) {
		self.channelId = channelId
		self.channelLabel = channelLabel
	}

	public static let `default` = Self(channelId: 0, channelLabel: "data")
}

extension DataChannelLabelledID {
	public var description: String {
		"""
		channelId: \(channelId),
		channelLabel: \(channelLabel)
		"""
	}
}

#if DEBUG
extension DataChannelLabelledID {
	public static let placeholder = Self.default
}
#endif // DEBUG

// MARK: - DataChannelIDTag
public enum DataChannelIDTag: Hashable {}

// MARK: - DataChannelLabelTag
public enum DataChannelLabelTag: Hashable {}
public typealias DataChannelID = Tagged<DataChannelIDTag, Int32>
public typealias DataChannelLabel = Tagged<DataChannelLabelTag, String>
