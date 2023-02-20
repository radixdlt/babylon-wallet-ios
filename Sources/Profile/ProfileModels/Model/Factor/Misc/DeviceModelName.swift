import Prelude
#if canImport(UIKit)
import DeviceKit
import UIKit
#endif

// MARK: - Device
public enum Device {}
public extension Device {
	@MainActor
	static func modelName() -> NonEmptyString {
		#if canImport(UIKit)
		guard
			let deviceName = DeviceKit.Device.current.name,
			let nonEmptyDeviceName = NonEmptyString(rawValue: deviceName)
		else {
			return "Unknown device"
		}
		return nonEmptyDeviceName
		#else
		return "Mac"
		#endif
	}
}
