import Foundation

// MARK: - RuntimeInfo
// Namespace
public enum RuntimeInfo {}

extension RuntimeInfo {
	public static let isAppStoreBuild = !(isDebug || isRunningInTestFlightEnvironment)

	public static let isDebug: Bool = {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}()
}

extension RuntimeInfo {
	private static let isAppStoreReceiptSandbox = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
	private static let hasEmbeddedMobileProvision = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
	private static let isRunningInTestFlightEnvironment = isAppStoreReceiptSandbox && !hasEmbeddedMobileProvision
}
