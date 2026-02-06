import Foundation
import Sargon

enum SargonDriversFactory {
	static func make(bundle: Bundle = .main) -> Drivers {
		let appVersion = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"

		return Drivers(
			networking: .shared,
			secureStorage: SargonSecureStorage(),
			entropyProvider: .shared,
			hostInfo: AppleHostInfoDriver(appVersion: appVersion),
			logging: SargonLoggingDriver(),
			eventBus: .shared,
			fileSystem: .shared,
			unsafeStorage: UnsafeStorage(
				userDefaults: UserDefaults(suiteName: UserDefaults.Dependency.radixSuiteName)!,
				keyMapping: .sargonOSMapping
			),
			profileStateChangeDriver: .shared,
			arculusCsdkDriver: ArculusCSDKDriver(),
			nfcTagDriver: NFCSessionClient()
		)
	}
}
