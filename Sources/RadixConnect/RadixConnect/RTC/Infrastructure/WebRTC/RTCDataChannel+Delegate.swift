import WebRTC

// MARK: - RTCDataChannel + Sendable
extension RTCDataChannel: @unchecked Sendable {}

// MARK: - RTCDataChannel + DataChannel
extension RTCDataChannel: DataChannel {
	func sendData(_ data: Data) {
		self.sendData(.init(data: data, isBinary: true))
	}
}

// MARK: - RTCDataChannelAsyncDelegate
final class RTCDataChannelAsyncDelegate: NSObject,
	RTCDataChannelDelegate,
	DataChannelDelegate,
	Sendable
{
	let receivedMessages: AsyncStream<Data>

	private let receivedMessagesContinuation: AsyncStream<Data>.Continuation

	override init() {
		(receivedMessages, receivedMessagesContinuation) = AsyncStream.streamWithContinuation()
		super.init()
	}

	func cancel() {
		receivedMessagesContinuation.finish()
	}
}

// MARK: RTCDataChannelDelegate
extension RTCDataChannelAsyncDelegate {
	func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		receivedMessagesContinuation.yield(buffer.data)
	}

	func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {}
}
