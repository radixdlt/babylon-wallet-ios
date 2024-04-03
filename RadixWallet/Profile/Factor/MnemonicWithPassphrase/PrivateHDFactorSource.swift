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
		name: String,
		model: DeviceFactorSource.Hint.Model,
		mnemonicWithPassphrase: MnemonicWithPassphrase = .testValueZooVote
	) -> Self {
		let deviceFactorSource = try! DeviceFactorSource.babylon(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			isMain: true,
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
