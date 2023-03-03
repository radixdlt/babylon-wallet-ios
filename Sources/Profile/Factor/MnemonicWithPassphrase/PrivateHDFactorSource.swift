import Foundation
import NonEmpty

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable {
	public let mnemonicWithPassphrase: MnemonicWithPassphrase

	// Only mutable so that `hint` inside factorSource can be changed
	// before persisted.
	public var factorSource: FactorSource

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

#if DEBUG
extension PrivateHDFactorSource {
	public static func testValue(hint: NonEmptyString) -> Self {
		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue
		let factorSource = try! FactorSource.babylon(mnemonicWithPassphrase: mnemonicWithPassphrase, hint: hint)
		return try! .init(mnemonicWithPassphrase: mnemonicWithPassphrase, factorSource: factorSource)
	}
}
#endif
