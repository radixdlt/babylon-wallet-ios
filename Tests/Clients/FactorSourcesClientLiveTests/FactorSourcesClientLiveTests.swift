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
			for: Set(accounts.map { Signer.Entity.account($0) }),
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
		func accountsOf(signingFactor: SigningFactor) -> [Profile.Network.Account] {
			signingFactor.signers.map(\.entity).compactMap { try? $0.asAccount() }
		}
		let device0Accounts = accountsOf(signingFactor: device0)
		XCTAssertEqual(device0Accounts.sorted(), [accounts[0], accounts[1]])
		let device1 = devicesSorted[1]
		let device1Accounts = accountsOf(signingFactor: device1)

		XCTAssertEqual(device1Accounts.sorted(), [accounts[2]])

		let ledgers = try XCTUnwrap(signingFactors[.ledgerHQHardwareWallet])
		XCTAssertEqual(Array(ledgers.rawValue).map(\.factorSource).sorted(), [.ledgerTwo])
		XCTAssertEqual(ledgers.count, 1)
		let ledger = ledgers.first
		XCTAssertEqual(accountsOf(signingFactor: ledger).sorted(), [accounts[3], accounts[4], accounts[5]])
	}
}

// MARK: - SigningFactor + Comparable
extension SigningFactor: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.factorSource < rhs.factorSource
	}
}

// MARK: - Profile.Network.Account + Comparable
extension Profile.Network.Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.appearanceID.rawValue < rhs.appearanceID.rawValue
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
				derivationPath: AccountDerivationPath.babylon(.init(
					networkID: .simulator,
					index: index,
					keyKind: .transactionSigning
				)).wrapAsDerivationPath()
			),
			displayName: "\(index)",
			extraProperties: .init(
				appearanceID: .fromIndex(Int(index))
			)
		)
	}
}
