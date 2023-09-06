import Foundation

// MARK: - RadixConnectConstants
public enum RadixConnectConstants {}

extension RadixConnectConstants {
	/// Connection URL
	public static let prodSignalingServer = URL(string: "wss://signaling-server.radixdlt.com")!

	public static let defaultSignalingServer: URL = prodSignalingServer
}
