import WebRTC

// MARK: - RadixConnectConstants
enum RadixConnectConstants {}

extension RadixConnectConstants {
	/// Connection URL
	static let prodSignalingServer = URL(string: "wss://signaling-server.radixdlt.com")!

	static let devSignalingServer = URL(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!

	static let defaultSignalingServer: URL = {
		#if DEBUG
		return devSignalingServer
		#else
		return prodSignalingServer
		#endif // DEBUG
	}()
}
