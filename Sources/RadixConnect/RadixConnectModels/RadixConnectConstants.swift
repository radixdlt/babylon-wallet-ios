import Foundation

// MARK: - RadixConnectConstants
public enum RadixConnectConstants {}

extension RadixConnectConstants {
	/// Connection URL
	public static let prodSignalingServer = URL(string: "wss://signaling-server.radixdlt.com")!

	public static let devSignalingServer = URL(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!

	public static let defaultSignalingServer: URL = {
		#if DEBUG
		return devSignalingServer
		#else
		return prodSignalingServer
		#endif // DEBUG
	}()
}
