import ClientTestingPrelude
import Cryptography
import FactorSourcesClient
@testable import FactorSourcesClientLive
@testable import Profile

// MARK: - FactorSourcesClientLiveTests
final class FactorSourcesClientLiveTests: TestCase {
	func testSigningFactors() throws {
		let accounts: [Profile.Network.Account] = [
			.new(factorSource: .deviceOne, index: 0), // 0
			.new(factorSource: .deviceOne, index: 1), // 1
			.new(factorSource: .deviceTwo, index: 0), // 2
			.new(factorSource: .ledgerTwo, index: 0), // 3
			.new(factorSource: .ledgerTwo, index: 1), // 4
			.new(factorSource: .ledgerTwo, index: 2), // 5
		]

		let signingFactors = try signingFactors(
			for: Set(accounts),
			from: [
				FactorSource.deviceOne,
				FactorSource.deviceTwo,
				FactorSource.ledgerOne,
				FactorSource.ledgerTwo,
			]
		)
		let devices = try XCTUnwrap(signingFactors[.device])
		XCTAssertEqual(Array(devices.rawValue).map(\.factorSource).sorted(), [.deviceOne, .deviceTwo])
		XCTAssertEqual(devices.count, 2)
		let devicesSorted = Array(devices.rawValue).sorted(by: { $0.factorSource < $1.factorSource })
		let device0 = devicesSorted[0]
		XCTAssertEqual(Array(device0.signers.rawValue).map(\.account).sorted(by: \.appearanceID.rawValue), [accounts[0], accounts[1]])
		let device1 = devicesSorted[1]
		XCTAssertEqual(Array(device1.signers.rawValue).map(\.account).sorted(by: \.appearanceID.rawValue), [accounts[2]])

		let ledgers = try XCTUnwrap(signingFactors[.ledgerHQHardwareWallet])
		XCTAssertEqual(Array(ledgers.rawValue).map(\.factorSource).sorted(), [.ledgerTwo])
		XCTAssertEqual(ledgers.count, 1)
		let ledger = ledgers.first
		XCTAssertEqual(Array(ledger.signers.rawValue).map(\.account).sorted(by: \.appearanceID.rawValue), [accounts[3], accounts[4], accounts[5]])
	}
}

// MARK: - SigningFactor + Comparable
extension SigningFactor: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.factorSource < rhs.factorSource
	}
}

// MARK: - FactorSource + Comparable
extension FactorSource: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.label.rawValue < rhs.label.rawValue
	}
}

extension FactorSource {
	static func device(_ label: String, olympiaCompat: Bool) -> Self {
		try! FactorSource(
			kind: .device,
			id: .init(data: .random(byteCount: 32)),
			label: .init(label),
			description: .init(rawValue: label),
			parameters: olympiaCompat ? .olympiaBackwardsCompatible : .babylon,
			storage: nil,
			addedOn: Date(),
			lastUsedOn: Date()
		)
	}

	static func ledger(_ label: String, olympiaCompat: Bool) -> Self {
		try! FactorSource(
			kind: .ledgerHQHardwareWallet,
			id: .init(data: .random(byteCount: 32)),
			label: .init(label),
			description: .init(rawValue: label),
			parameters: olympiaCompat ? .olympiaBackwardsCompatible : .babylon,
			storage: nil,
			addedOn: Date(),
			lastUsedOn: Date()
		)
	}

	static let deviceOne = Self.device("One", olympiaCompat: true)
	static let deviceTwo = Self.device("Two", olympiaCompat: false)
	static let ledgerOne = Self.ledger("One", olympiaCompat: false)
	static let ledgerTwo = Self.ledger("Two", olympiaCompat: true)
}

extension Profile.Network.Account {
	static func new(factorSource: FactorSource, index: UInt32) -> Self {
		try! .init(
			networkID: .simulator,
			factorInstance: .init(
				factorSourceID: factorSource.id,
				publicKey: .eddsaEd25519(Curve25519.Signing.PrivateKey().publicKey),
				derivationPath: AccountHierarchicalDeterministicDerivationPath(
					networkID: .simulator,
					index: index,
					keyKind: .transactionSigning
				).wrapAsDerivationPath()
			),
			displayName: "\(index)",
			extraProperties: .init(
				appearanceID: .fromIndex(Int(index))
			)
		)
	}
}
