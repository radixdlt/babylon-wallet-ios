import Prelude
import Resources
#if canImport(UIKit)
import DeviceKit
import UIKit
#endif

// MARK: - Device
public enum Device {}
public extension Device {
	/// Returns: "Alex Phone - iPhone SE (2nd generation)" if we
	/// successfully managed to read the name, otherwise fallback:
	/// to just "iPhone SE (2nd generation)", and in case that fails
	/// falls back to "Unknown Apple Device".
	@MainActor static func modelDescription() -> NonEmptyString {
		#if canImport(UIKit)
		let modelDescription_: String = {
			let currentDevice = DeviceKit.Device.current
			let deviceDescription_ = currentDevice.description
			guard
				let name = currentDevice.name
			else {
				return deviceDescription_
			}
			return "\(name) - \(deviceDescription_)"
		}()
		return NonEmptyString(rawValue: modelDescription_) ?? NonEmptyString(rawValue: L10n.FactorSource.Device.iPhoneModelFallback)!
		#else
		return "Mac" // should never be displayed to any iPhone user ever...
		#endif
	}
}
