
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - FactorSourcesCodableTests
final class FactorSourcesCodableTests: TestCase {
	func omit_test_generate_vector() throws {
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

			let babylon = try DeviceFactorSource.babylon(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				isMain: true,
				model: "iPhone 16",
				name: "New phone"
			)

			anyFactorSources.append(babylon)

			let olympia = try DeviceFactorSource.olympia(
				mnemonicWithPassphrase: mnemonicWithPassphrase,
				model: "iPhone 14 Pro Max",
				name: "Old phone"
			)
			anyFactorSources.append(olympia)

			let ledger = try LedgerHardwareWalletFactorSource.model(
				.nanoS,
				name: "Orange",
				deviceID: .init(.deadbeef32Bytes)
			)

			anyFactorSources.append(ledger)

			try anyFactorSources.append(
				OffDeviceMnemonicFactorSource.from(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					label: "Test"
				)
			)

			let accountAddress = try! AccountAddress(validatingAddress: "account_rdx1283u6e8r2jnz4a3jwv0hnrqfr5aq50yc9ts523sd96hzfjxqqcs89q")
			anyFactorSources.append(
				TrustedContactFactorSource.from(
					radixAddress: accountAddress,
					emailAddress: "hi@rdx.works",
					name: "My friend"
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
			bundle: Bundle(for: Self.self),
			jsonName: "factor_sources"
		) { (factorSources: [FactorSource]) in
			guard factorSources.count == 5 else {
				XCTFail("wrong length")
				return
			}

			let babylon = try factorSources[0].extract(as: DeviceFactorSource.self)
			XCTAssertEqual(babylon.id.kind, .device)

			let olympia: DeviceFactorSource = try factorSources[1].extract()
			XCTAssertEqual(olympia.id.kind, .device)

			let ledger = try factorSources[2].extract(as: LedgerHardwareWalletFactorSource.self)
			XCTAssertEqual(ledger.id.kind, .ledgerHQHardwareWallet)

			let offDeviceMnemonic = try factorSources[3].extract(as: OffDeviceMnemonicFactorSource.self)
			XCTAssertEqual(offDeviceMnemonic.id.kind, .offDeviceMnemonic)

			let trustedContact = try factorSources[4].extract(as: TrustedContactFactorSource.self)
			XCTAssertEqual(trustedContact.id.kind, .trustedContact)
		}
	}
}

extension Data {
	static func from(_ byte: UInt8) -> Self {
		Self([UInt8](repeating: 0x00, count: 31) + [byte])
	}
}
