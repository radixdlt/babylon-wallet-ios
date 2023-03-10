import Foundation
import NonEmpty

// MARK: - PrivateHDFactorSource
public struct PrivateHDFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { factorSource.id }
	public let mnemonicWithPassphrase: MnemonicWithPassphrase

	// Only mutable so that `hint` inside factorSource can be changed
	// before persisted.
	public var factorSource: FactorSource

	public init(
		mnemonicWithPassphrase: MnemonicWithPassphrase,
		factorSource: FactorSource
	) throws {
		self.factorSource = try factorSource.assertIsHD()
		let hdRoot = try mnemonicWithPassphrase.hdRoot()
		let factorSourceID = try FactorSource.id(fromRoot: hdRoot)
		guard factorSourceID == factorSource.id else { fatalError("discrepancy") }
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
	}
}

#if DEBUG
extension PrivateHDFactorSource {
	public static func testValue(hint: NonEmptyString) -> Self {
		let mnemonicWithPassphrase = MnemonicWithPassphrase.testValue

		let factorSource = try! FactorSource(
			kind: .device,
			id: FactorSource.id(fromRoot: mnemonicWithPassphrase.hdRoot()),
			hint: hint,
			parameters: .babylon,
			storage: .forDevice(.init()),
			addedOn: .init(timeIntervalSince1970: 0),
			lastUsedOn: .init(timeIntervalSince1970: 0)
		)

		return try! .init(
			mnemonicWithPassphrase: mnemonicWithPassphrase,
			factorSource: factorSource
		)
	}
}
#endif
