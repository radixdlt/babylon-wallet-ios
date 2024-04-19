import Foundation
import Sargon

extension FactorSources {
	/// Babylon `device` factor source
	public var babylonDevice: DeviceFactorSource {
		babylonDeviceFactorSources().first
	}

	public func babylonDeviceFactorSources() -> NonEmpty<IdentifiedArrayOf<DeviceFactorSource>> {
		let array = compactMap { $0.extract(DeviceFactorSource.self) }.filter(\.isBDFS)
		let identifiedArray = array.asIdentified()

		guard
			let nonEmpty = NonEmpty<IdentifiedArrayOf<DeviceFactorSource>>(rawValue: identifiedArray)
		else {
			let errorMsg = "Critical failure, every single execution path of the babylon wallet should ALWAYS contain a babylon device factorsource, did you do something weird in a test?"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			fatalError(errorMsg)
		}

		return nonEmpty
	}

	private func device(filter: (FactorSource) -> Bool) -> FactorSource? {
		self.filter { $0.kind == .device }
			.first(where: { filter($0) })
	}
}
