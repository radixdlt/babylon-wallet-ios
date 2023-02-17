import Foundation

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Equatable {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
	public let factorSource: FactorSource

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: FactorSource
	) throws {
		let hdRoot = try mnemonicWithPassphrase.hdRoot()

		let factorSourceID = try FactorSource.id(fromRoot: hdRoot)

		guard factorSourceID == factorSource.id else { fatalError("discrepancy") }
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
		self.factorSource = factorSource
	}
}
