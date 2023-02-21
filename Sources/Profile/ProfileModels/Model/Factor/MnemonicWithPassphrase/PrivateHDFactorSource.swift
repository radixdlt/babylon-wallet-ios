import Foundation

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
	public let factorSource: FactorSource

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: FactorSource
	) throws {
		guard factorSource.kind.isHD else {
			fatalError("must be HD")
		}
		let hdRoot = try mnemonicWithPassphrase.hdRoot()

		let factorSourceID = try FactorSource.id(fromRoot: hdRoot)

		guard factorSourceID == factorSource.id else { fatalError("discrepancy") }
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
		self.factorSource = factorSource
	}
}
