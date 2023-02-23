import Foundation
import NonEmpty

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase
	public private(set) var factorSource: FactorSource

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

extension PrivateHDFactorSource {
	public func changing(hint newHint: NonEmptyString) -> Self {
		var copy = self
		copy.factorSource = factorSource.changing(hint: newHint)
		return copy
	}
}
