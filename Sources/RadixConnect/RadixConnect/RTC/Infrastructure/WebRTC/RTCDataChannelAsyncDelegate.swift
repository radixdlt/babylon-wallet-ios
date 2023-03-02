import WebRTC

// MARK: - RTCDataChannelAsyncDelegate
final class RTCDataChannelAsyncDelegate: NSObject,
	RTCDataChannelDelegate,
	DataChannelDelegate,
	Sendable
{
	let onMessageReceived: AsyncStream<Data>
	let onReadyState: AsyncStream<DataChannelState>

	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation
	private let onReadyStateContinuation: AsyncStream<DataChannelState>.Continuation

	override init() {
		(onMessageReceived, onMessageReceivedContinuation) = AsyncStream.streamWithContinuation(Data.self)
		(onReadyState, onReadyStateContinuation) = AsyncStream.streamWithContinuation(DataChannelState.self)
		super.init()
	}

	func cancel() {
		onMessageReceivedContinuation.finish()
		onReadyStateContinuation.finish()
	}
}

// MARK: RTCDataChannelDelegate
extension RTCDataChannelAsyncDelegate {
	func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		onMessageReceivedContinuation.yield(buffer.data)
	}

	func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		onReadyStateContinuation.yield(.init(from: dataChannel.readyState))
	}
}

private extension DataChannelState {
	init(from rtc: RTCDataChannelState) {
		switch rtc {
		case .open: self = .open
		case .connecting: self = .connecting
		case .closed: self = .closed
		case .closing: self = .closing
		@unknown default: fatalError() // unreachable
		}
	}
}
