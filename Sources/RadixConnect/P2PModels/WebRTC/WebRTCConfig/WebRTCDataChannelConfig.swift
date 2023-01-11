import Foundation

// MARK: - WebRTCDataChannelConfig
/// Swift wrapper of `RTCPeerConnectionFactory`.
///
/// We do NOT include `channelId` here, because we will seed it from WrapRTC.Peer's `connectionId`,
/// by "seed" we refer to the fact that the channelId on `RTCPeerConnectionFactory` is an Int32 but a
/// `P2PConnectionID` is a 256bit integer, so we need to use the first 4 bytes.
public struct WebRTCDataChannelConfig: Sendable, Hashable, Codable, CustomStringConvertible {
	public let dataChannelLabelledID: DataChannelLabelledID

	/** Set to `true` if the channel has been externally negotiated and we do not send
	 * an in-band signalling in the form of an "open" message.
	 */
	public let isNegotiated: Bool

	/** Set to `true` if ordered delivery is required. */
	public let isOrdered: Bool

	/**
	 * Max period in milliseconds in which retransmissions will be sent. After this
	 * time, no more retransmissions will be sent. -1 if unset.
	 */
	public let maxPacketLifeTime: Int32

	/** The max number of retransmissions. -1 if unset. */
	public let maxRetransmits: Int32

	public init(
		dataChannelLabelledID: DataChannelLabelledID = .default,
		isNegotiated: Bool = true,
		isOrdered: Bool = true,
		maxPacketLifeTime: Int? = nil,
		maxRetransmits: Int? = nil
	) {
		self.dataChannelLabelledID = dataChannelLabelledID
		self.isNegotiated = isNegotiated
		self.isOrdered = isOrdered
		self.maxPacketLifeTime = maxPacketLifeTime.map { Int32($0) } ?? -1
		self.maxRetransmits = maxRetransmits.map { Int32($0) } ?? -1
	}

	public static let `default` = Self()
}

public extension WebRTCDataChannelConfig {
	var channelId: DataChannelID { dataChannelLabelledID.channelId }

	var channelLabel: DataChannelLabel { dataChannelLabelledID.channelLabel }

	var description: String {
		"""
		channelId: \(channelId),
		channelLabel: \(channelLabel),
		isNegotiated: \(isNegotiated),
		isOrdered: \(isOrdered),
		maxPacketLifeTime: \(maxPacketLifeTime),
		maxPacketLifeTime: \(maxPacketLifeTime),
		"""
	}
}

#if DEBUG
public extension WebRTCDataChannelConfig {
	static let placeholder: Self = .init(dataChannelLabelledID: .placeholder)
}
#endif // DEBUG
