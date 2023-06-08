import Cryptography
import EngineToolkit
import Profile
import TestingPrelude

// MARK: - FactorSourcesCodableTests
final class FactorSourcesCodableTests: TestCase {
	func omit_test_generate_vector() throws {
		let networkID = NetworkID.kisharnet

		let factorSources: [FactorSource] = try withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 1_690_801_871))
		} operation: {
			let mnemonic = try! Mnemonic(
				phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
				language: .english
			)
			let mnemonicWithPassphrase = MnemonicWithPassphrase(
				mnemonic: mnemonic,
				passphrase: "Radix"
			)

			var anyFactorSources: [any FactorSourceProtocol] = []

			var babylon = try DeviceFactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				model: "iPhone 16",
				name: "New phone"
			)
			babylon.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(
				for: .account,
				networkID: networkID
			)
			babylon.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(
				for: .account,
				networkID: networkID
			)
			babylon.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(
				for: .identity,
				networkID: networkID
			)

			anyFactorSources.append(babylon)

			let olympia = try DeviceFactorSource.olympia(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				model: "iPhone 14 Pro Max",
				name: "Old phone"
			)
			XCTAssertNil(olympia.nextDerivationIndicesPerNetwork)
			anyFactorSources.append(olympia)

			var ledger = try LedgerHardwareWalletFactorSource.model(
				.nanoS,
				name: "Orange",
				deviceID: .init(.deadbeef32Bytes)
			)
			ledger.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(
				for: .account,
				networkID: networkID
			)
			anyFactorSources.append(ledger)

			try anyFactorSources.append(
				OffDeviceMnemonicFactorSource.from(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					label: "Test"
				)
			)

			return anyFactorSources.map { $0.embed() }
		}

		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		jsonEncoder.dateEncodingStrategy = .iso8601
		let data = try jsonEncoder.encode(factorSources)
		print(String(data: data, encoding: .utf8)!)
	}

	func test_factor_sources_codable() throws {
		try testFixture(
			bundle: .module,
			jsonName: "factor_sources"
		) { (factorSources: [FactorSource]) in
			guard factorSources.count == 4 else {
				XCTFail("wrong length")
				return
			}

			let babylon = try factorSources[0].extract(as: DeviceFactorSource.self)
			XCTAssertEqual(babylon.id.factorSourceKind, .device)

			let olympia: DeviceFactorSource = try factorSources[1].extract()
			XCTAssertEqual(olympia.id.factorSourceKind, .device)

			let ledger = try factorSources[2].extract(as: LedgerHardwareWalletFactorSource.self)
			XCTAssertEqual(ledger.id.factorSourceKind, .ledgerHQHardwareWallet)

			let offDeviceMnemonic = try factorSources[3].extract(as: OffDeviceMnemonicFactorSource.self)
			XCTAssertEqual(offDeviceMnemonic.id.factorSourceKind, .offDeviceMnemonic)
		}
	}
}

extension FactorSourceID {
	static func from(_ byte: UInt8, sourceKind: FactorSourceKind) -> Self {
		try! .init(factorSourceKind: sourceKind, hash: .from(byte))
	}
}

extension Data {
	static func from(_ byte: UInt8) -> Self {
		Self([UInt8](repeating: 0x00, count: 31) + [byte])
	}
}
