import Prelude

public typealias FactorSources = NonEmpty<IdentifiedArrayOf<FactorSource>>

// MARK: - FactorSourceWithIDNotFound
struct FactorSourceWithIDNotFound: Swift.Error {}
extension FactorSources {
	public mutating func updateFactorSource(
		id: FactorSourceID,
		_ mutate: (inout FactorSource) throws -> Void
	) throws {
		guard var factorSource = self[id: id] else {
			throw FactorSourceWithIDNotFound()
		}
		try mutate(&factorSource)
		var identifiedArrayOfFactorSources = self.rawValue
		identifiedArrayOfFactorSources[id: id] = factorSource
		self = .init(rawValue: .init(uncheckedUniqueElements: identifiedArrayOfFactorSources))!
	}
}

extension FactorSources {
	/// Babylon `device` factor source
	public var babylonDevice: HDOnDeviceFactorSource {
		guard
			let babylon = device(filter: { !$0.supportsOlympia }),
			let hdFactorSource = try? HDOnDeviceFactorSource(factorSource: babylon)
		else {
			let errorMsg = "Critical failure, every single execution path of the babylon wallet should ALWAYS contain a 'babylon' device factorsource, did you do something weird in a test?"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			fatalError(errorMsg)
		}
		return hdFactorSource
	}

	public func hdOnDeviceFactorSource() -> NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>> {
		guard
			case let array = self.compactMap({
				try? HDOnDeviceFactorSource(factorSource: $0)
			}),
			case let identifiedArray = IdentifiedArrayOf<HDOnDeviceFactorSource>(uncheckedUniqueElements: array),
			let nonEmpty = NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>(rawValue: identifiedArray)
		else {
			let errorMsg = "Critical failure, every single execution path of the babylon wallet should ALWAYS contain a device factorsource, did you do something weird in a test?"
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

#if DEBUG
extension FactorSources {
	public init(_ factorSource: FactorSource) {
		self.init(uniqueElements: [factorSource])
	}

	public init(uniqueElements: some Swift.Collection<FactorSource>) {
		precondition(!uniqueElements.isEmpty)
		self.init(rawValue: .init(uniqueElements: uniqueElements))!
	}

	public static let previewValue: Self = .init(.previewValueDevice)
}

#endif // DEBUG
