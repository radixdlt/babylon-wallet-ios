import Foundation
import Sargon

extension DeviceFactorSource {
	func removingMainFlag() -> Self {
		var copy = self
		copy.common.flags.removeAll(where: { $0 == .main })
		return copy
	}
}
