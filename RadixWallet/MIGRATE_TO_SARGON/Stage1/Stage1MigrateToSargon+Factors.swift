// MARK: - FactorSourceWithIDNotFound
struct FactorSourceWithIDNotFound: Swift.Error {}
extension FactorSources {
	mutating func updateFactorSource(
		id: some FactorSourceIDProtocol,
		_ mutate: @escaping (inout FactorSource) throws -> Void
	) throws {
		try updateFactorSource(id: id.asGeneral, mutate)
	}

	mutating func updateFactorSource(
		id: FactorSourceID,
		_ mutate: (inout FactorSource) throws -> Void
	) throws {
		guard var factorSource = self[id: id] else {
			throw FactorSourceWithIDNotFound()
		}
		try mutate(&factorSource)
		let updated = self.updateOrAppend(factorSource)
		assert(updated != nil)
	}

	/// Babylon `device` factor source
	var babylonDevice: DeviceFactorSource {
		babylonDeviceFactorSources().first
	}
}

extension FactorSources {
	// Cyon: We can migrate this to Sargon if we declare with the macro a NeverEmptyCollection
	// of DeviceFactorSources, being a "cousing" to `FactorSources` which has `FactorSource` element,
	// that is probably a good idea since it is actually the collection of DeviceFactorSources
	// specifically which is never allowed to be empty. Then we can UniFFI export a method
	// of FactorSources returning `DeviceFactorSources` (never empty) and maybe even in the future
	// remove the `NonEmpty` Swift crate (which I've been over using since start...).
	func babylonDeviceFactorSources() -> NonEmpty<IdentifiedArrayOf<DeviceFactorSource>> {
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
