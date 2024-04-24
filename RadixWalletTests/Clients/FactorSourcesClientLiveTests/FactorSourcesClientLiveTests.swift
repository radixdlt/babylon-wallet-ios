@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - FactorSourcesClientLiveTests
final class FactorSourcesClientLiveTests: TestCase {
	func testSigningFactors() throws {
		let accounts: [Account] = [
			.new(factorSource: .deviceOne, index: 0), // 0
			.new(factorSource: .deviceOne, index: 1), // 1
			.new(factorSource: .deviceTwo, index: 0), // 2
			.new(factorSource: .ledgerTwo, index: 0), // 3
			.new(factorSource: .ledgerTwo, index: 1), // 4
			.new(factorSource: .ledgerTwo, index: 2), // 5
		]

		let signingFactors = try signingFactors(
			for: Set(accounts.map { AccountOrPersona.account($0) }),
			from: [
				FactorSource.deviceOne,
				FactorSource.deviceTwo,
				FactorSource.ledgerOne,
				FactorSource.ledgerTwo,
			],
			signingPurpose: .signTransaction(.manifestFromDapp)
		)

		XCTAssertEqual(signingFactors.expectedSignatureCount, 6)

		let devices = try XCTUnwrap(signingFactors[.device])
		XCTAssertEqual(Array(devices.rawValue).map(\.factorSource).sorted(), [.deviceOne, .deviceTwo])
		XCTAssertEqual(devices.count, 2)
		let devicesSorted = Array(devices.rawValue).sorted(by: { $0.factorSource < $1.factorSource })
		let device0 = devicesSorted[0]
		func accountsOf(signingFactor: SigningFactor) -> [Account] {
			signingFactor.signers.map(\.entity).compactMap { try? $0.asAccount() }
		}
		let device0Accounts = accountsOf(signingFactor: device0)
		XCTAssertEqual(device0Accounts.sorted(), [accounts[0], accounts[1]])
		let device1 = devicesSorted[1]
		let device1Accounts = accountsOf(signingFactor: device1)

		XCTAssertEqual(device1Accounts.sorted(), [accounts[2]])

		let ledgers = try XCTUnwrap(signingFactors[.ledgerHqHardwareWallet])
		XCTAssertEqual(Array(ledgers.rawValue).map(\.factorSource).sorted(), [.ledgerTwo])
		XCTAssertEqual(ledgers.count, 1)
		let ledger = ledgers.first
		XCTAssertEqual(accountsOf(signingFactor: ledger).sorted(), [accounts[3], accounts[4], accounts[5]])
	}

	func test_new_bdfs() async throws {
		let userDefaults = UserDefaults.Dependency.ephemeral()
		let profile = Profile.sample
		userDefaults.set(string: profile.header.id.uuidString, key: .activeProfileID)

		try await withTestClients {
			$0.userDefaults = userDefaults
			$0.secureStorageClient.loadDeviceInfo = { profile.header.creatingDevice }
			$0.secureStorageClient.loadProfile = { _ in profile }
		} operation: {
			let sut = FactorSourcesClient.liveValue
			let newMainBDFS = try await sut.createNewMainBDFS()
			try await sut.saveNew(mainBDFS: newMainBDFS)
			let usedMainBDFS = try await sut.getMainDeviceFactorSource()
			XCTAssertNoDifference(newMainBDFS.factorSource, usedMainBDFS)
		}
	}
}

// MARK: - SigningFactor + Comparable
extension SigningFactor: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.factorSource < rhs.factorSource
	}
}

// MARK: - Account + Comparable
extension Account: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.appearanceID < rhs.appearanceID
	}
}

// MARK: - DeviceFactorSource + Comparable
extension DeviceFactorSource: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.hint.name < rhs.hint.name
	}
}

// MARK: - LedgerHardwareWalletFactorSource + Comparable
extension LedgerHardwareWalletFactorSource: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.hint.name < rhs.hint.name
	}
}

// MARK: - FactorSource + Comparable
extension FactorSource: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.device(l), .device(r)):
			l < r
		case let (.ledger(l), .ledger(r)):
			l < r
		default: true
		}
	}
}

extension FactorSource {
	static func device(_ name: String, olympiaCompat: Bool) -> Self {
		withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			let device = try! DeviceFactorSource(
				id: .device(hash: Data.random(byteCount: 32)),
				common: .init(
					cryptoParameters: olympiaCompat ? FactorSource.CryptoParameters.Preset.babylonWithOlympiaCompatability.cryptoParameters : .babylon
				),
				hint: .init(name: name, model: "", mnemonicWordCount: .twentyFour)
			)
			return device.embed()
		}
	}

	static func ledger(_ name: String, olympiaCompat: Bool) -> Self {
		withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
		} operation: {
			let ledger = try! LedgerHardwareWalletFactorSource(
				id: .init(kind: .ledgerHQHardwareWallet, hash: Data.random(byteCount: 32)),
				common: .init(
					cryptoParameters: olympiaCompat ? FactorSource.CryptoParameters.Preset.babylonWithOlympiaCompatability.cryptoParameters : .babylon
				),
				hint: .init(name: .init(name), model: .nanoS)
			)
			return ledger.embed()
		}
	}

	static let deviceOne = Self.device("One", olympiaCompat: true)
	static let deviceTwo = Self.device("Two", olympiaCompat: false)
	static let ledgerOne = Self.ledger("One", olympiaCompat: false)
	static let ledgerTwo = Self.ledger("Two", olympiaCompat: true)
}

extension Account {
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
				appearanceID: .fromNumberOfAccounts(Int(index))
			)
		)
	}
}

extension FactorSourcesClient {
	func saveNew(mainBDFS: PrivateHierarchicalDeterministicFactorSource) async throws {
		try await saveNewMainBDFS(mainBDFS.factorSource)
	}
}
