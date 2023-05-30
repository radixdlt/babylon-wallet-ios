import Prelude

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
	public let factorSource: DeviceFactorSource

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: DeviceFactorSource
	) throws {
		let hdRoot = try mnemonicWithPassphrase.hdRoot()
		let factorSourceID = try FactorSource.id(fromRoot: hdRoot)
		guard factorSourceID == factorSource.id else {
			loggerGlobal.critical("FactorSourceOD of new factor does not match mnemonic.")
			throw CriticalDisrepancyBetweenFactorSourceID()
		}
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
		self.factorSource = factorSource
	}

	struct CriticalDisrepancyBetweenFactorSourceID: Swift.Error {}
}

// #if DEBUG
// extension PrivateHDFactorSource {
//	public static func testValue(
//		label: FactorSource.Label,
//		description: FactorSource.Description
//	) -> Self {
//		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue
//
//		let factorSource = try! FactorSource(
//			kind: .device,
//			id: FactorSource.id(fromRoot: mnemonicWithPassphrase.hdRoot()),
//			label: label,
//			description: description,
//			cryptoParameters: .babylon,
//			storage: .entityCreating(.init()),
//			addedOn: .init(timeIntervalSince1970: 0),
//			lastUsedOn: .init(timeIntervalSince1970: 0)
//		)
//
//		return try! .init(
//			mnemonicWithPassphrase: mnemonicWithPassphrase,
//			factorSource: factorSource
//		)
//	}
// }
// #endif
