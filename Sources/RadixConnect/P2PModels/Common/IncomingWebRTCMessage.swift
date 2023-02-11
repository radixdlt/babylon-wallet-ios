import Foundation

// MARK: - IncomingWebRTCMessage
/// A message received from an `RTCDataChannel`
public struct IncomingWebRTCMessage: Sendable, Hashable, CustomStringConvertible {
	public let message: Data
	public let connectionID: P2PConnectionID
	public let dataChannelLabelledID: DataChannelLabelledID
	public let receivedOn: Date

	public init(
		message: Data,
		connectionID: P2PConnectionID,
		dataChannelLabelledID: DataChannelLabelledID,
		receivedOn: Date = .init()
	) {
		self.message = message
		self.connectionID = connectionID
		self.dataChannelLabelledID = dataChannelLabelledID
		self.receivedOn = receivedOn
	}
}

extension IncomingWebRTCMessage {
	public var description: String {
		"""
		connectionID: \(connectionID),
		dataChannelLabelledID: \(dataChannelLabelledID),
		message: #\(message.count) bytes,
		receivedOn: \(receivedOn.ISO8601Format())
		"""
	}
}
