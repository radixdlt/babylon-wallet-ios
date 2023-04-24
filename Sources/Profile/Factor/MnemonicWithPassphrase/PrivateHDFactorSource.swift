import Prelude

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { hdOnDeviceFactorSource.id }
	public let mnemonicWithPassphrase: MnemonicWithPassphrase

	public let hdOnDeviceFactorSource: HDOnDeviceFactorSource

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		hdOnDeviceFactorSource: HDOnDeviceFactorSource
	) throws {
		self.hdOnDeviceFactorSource = hdOnDeviceFactorSource // try factorSource.assertIsHD()
		let hdRoot = try mnemonicWithPassphrase.hdRoot()
		let factorSourceID = try FactorSource.id(fromRoot: hdRoot)
		guard factorSourceID == hdOnDeviceFactorSource.id else {
			loggerGlobal.critical("FactorSourceOD of new factor does not match mnemonic.")
			throw CriticalDisrepancyBetweenFactorSourceID()
		}
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
	}

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: FactorSource
	) throws {
		try self.init(mnemonicWithPassphrase: mnemonicWithPassphrase, hdOnDeviceFactorSource: .init(factorSource: factorSource))
	}

	struct CriticalDisrepancyBetweenFactorSourceID: Swift.Error {}
}

#if DEBUG
extension PrivateHDFactorSource {
	public static func testValue(
		label: FactorSource.Label,
		description: FactorSource.Description
	) -> Self {
		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue

		let factorSource = try! FactorSource(
			kind: .device,
			id: FactorSource.id(fromRoot: mnemonicWithPassphrase.hdRoot()),
			label: label,
			description: description,
			parameters: .babylon,
			storage: .entityCreating(.init()),
			addedOn: .init(timeIntervalSince1970: 0),
			lastUsedOn: .init(timeIntervalSince1970: 0)
		)

		let hdOnDeviceFactorSource = try! HDOnDeviceFactorSource(factorSource: factorSource)

		return try! .init(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			hdOnDeviceFactorSource: hdOnDeviceFactorSource
		)
	}
}
#endif
