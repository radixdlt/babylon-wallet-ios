import Foundation
import Sargon

extension DeviceFactorSource {
	public func embed() -> FactorSource {
		.device(value: self)
	}
}
