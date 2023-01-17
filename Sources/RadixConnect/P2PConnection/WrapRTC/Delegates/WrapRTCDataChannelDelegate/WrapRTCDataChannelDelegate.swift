import P2PModels
import Prelude
import WebRTC

// MARK: - WrapPeerConnectionWithDataChannel.WrapRTCDataChannelDelegate
extension WrapPeerConnectionWithDataChannel {
	final class WrapRTCDataChannelDelegate: NSObject, RTCDataChannelDelegate {
		let connectionID: P2PConnectionID
		weak var delegate: WebRTCDataChannelDelegate?
		init(
			connectionID: P2PConnectionID,
			delegate: WebRTCDataChannelDelegate
		) {
			self.connectionID = connectionID
			self.delegate = delegate
			super.init()
		}
	}
}

// MARK: RTCDataChannelDelegate impl
extension WrapPeerConnectionWithDataChannel.WrapRTCDataChannelDelegate {
	func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		let ignored = "dataChannelDidChangeState event (changed to: \((try? DataChannelState(rtcDataChannelState: dataChannel.readyState).description) ?? String(describing: dataChannel.readyState)) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		do {
			let readyState = try DataChannelState(rtcDataChannelState: dataChannel.readyState)
			delegate.dataChannel(labelledID: dataChannel.labelledChannelID, didChangeReadyState: readyState)
		} catch {
			loggerGlobal.error("\(ignored), since failed to bridge to `\(DataChannelState.self)`, failure: \(error)")
		}
	}

	func dataChannel(
		_ dataChannel: RTCDataChannel,
		didReceiveMessageWith buffer: RTCDataBuffer
	) {
		let ignored = "dataChannel:didReceiveMessageWith (received: #\(buffer.data.count) bytes) IGNORED"
		guard let delegate else {
			loggerGlobal.notice("\(ignored), since delegate is nil")
			return
		}
		loggerGlobal.trace("WrapRTC peer id=\(connectionID) received #\(buffer.data.count) bytes.")
		delegate.dataChannel(labelledID: dataChannel.labelledChannelID, didReceiveMessageData: buffer.data)
	}
}
