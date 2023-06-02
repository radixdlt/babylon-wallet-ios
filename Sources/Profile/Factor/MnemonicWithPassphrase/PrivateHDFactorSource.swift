import Prelude

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
	public let factorSource: DeviceFactorSource
	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: DeviceFactorSource
	) throws {
		let hdRoot = try mnemonicWithPassphrase.hdRoot()
		let factorSourceID = try FactorSource.id(fromRoot: hdRoot, factorSourceKind: factorSource.kind)
		guard factorSourceID == factorSource.id else {
			loggerGlobal.critical("FactorSourceOD of new factor does not match mnemonic.")
			throw CriticalDisrepancyBetweenFactorSourceID()
		}
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
		self.factorSource = factorSource
	}

	struct CriticalDisrepancyBetweenFactorSourceID: Swift.Error {}
}

#if DEBUG
extension PrivateHDFactorSource {
	public static func testValue(
		name: DeviceFactorSource.Hint.Name,
		model: DeviceFactorSource.Hint.Model
	) -> Self {
		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue

		let deviceFactorSource = try! DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			model: model,
			name: name,
			addedOn: .init(timeIntervalSince1970: 0),
			lastUsedOn: .init(timeIntervalSince1970: 0)
		)

		return try! .init(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			factorSource: deviceFactorSource
		)
	}
}
#endif
