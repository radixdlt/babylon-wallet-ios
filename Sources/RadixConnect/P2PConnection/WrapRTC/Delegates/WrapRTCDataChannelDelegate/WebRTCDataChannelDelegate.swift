import P2PModels
import Prelude

// MARK: - WebRTCDataChannelDelegate
public protocol WebRTCDataChannelDelegate: AnyObject {
	func dataChannel(labelledID: DataChannelLabelledID, didChangeReadyState: DataChannelState)
	func dataChannel(labelledID: DataChannelLabelledID, didReceiveMessageData: Data)
}

extension WebRTCDataChannelDelegate {
	public func dataChannel(labelledID: DataChannelLabelledID, didChangeReadyState: DataChannelState) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED \(String(describing: didChangeReadyState))")
	}

	public func dataChannel(labelledID: DataChannelLabelledID, didReceiveMessageData: Data) {
		loggerGlobal.warning("NOT IMPLEMENTED: \(#function), IGNORED #\(didReceiveMessageData.count) bytes received.")
	}
}
