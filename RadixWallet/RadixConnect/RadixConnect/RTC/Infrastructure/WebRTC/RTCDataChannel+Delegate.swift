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
	let dataChannelReadyStates: AsyncStream<DataChannelReadyState>
	private let receivedMessagesContinuation: AsyncStream<Data>.Continuation
	private let dataChannelReadyStatesContinuation: AsyncStream<DataChannelReadyState>.Continuation

	override init() {
		(receivedMessages, receivedMessagesContinuation) = AsyncStream.streamWithContinuation()
		(dataChannelReadyStates, dataChannelReadyStatesContinuation) = AsyncStream.streamWithContinuation()
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

	func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		dataChannelReadyStatesContinuation.yield(.init(rtc: dataChannel.readyState))
	}
}

extension DataChannelReadyState {
	init(rtc: RTCDataChannelState) {
		switch rtc {
		case .connecting:
			self = .connecting
		case .open:
			self = .connected
		case .closing:
			self = .closing
		case .closed:
			self = .closed
		@unknown default:
			self = .closed
		}
	}
}
