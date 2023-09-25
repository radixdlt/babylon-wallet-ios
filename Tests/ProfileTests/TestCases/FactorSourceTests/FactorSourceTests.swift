@testable import Profile
import TestingPrelude

final class FactorSourceTests: TestCase {
	// THIS TEST IS NEVER EVER EVER EVER ALLOWED TO FAIL!!! If it does, user might
	// lose their funds!!!!!!
	func test_assert_factorSourceID_description_is_unchanged() async throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "equip will roof matter pink blind book anxiety banner elbow sun young",
			language: .english
		)
		let root = try HD.Root(seed: curve25519FactorSourceMnemonic.seed(passphrase: "Radix... just imagine!"))
		let key = try root.derivePublicKey(
			path: .getID,
			curve: Curve25519.self
		)
		let factorSourceID = try FactorSource.id(fromRoot: root, factorSourceKind: .device)
		guard factorSourceID.description == "device:4af22ea955d53263a712d897a797df8388e13b8e7b3f30d7d7da88028b724d60" else {
			fatalError("CRITICAL UNIT TEST FAILURE - LOSS OF FUNDS POSSIBLE.")
		}
	}

	func test_factor_source_id() async throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)
		let root = try HD.Root(seed: curve25519FactorSourceMnemonic.seed())
		let key = try root.derivePublicKey(
			path: .init(
				children: [
					.bip44Purpose,
					.coinType,
					.getID,
				],
				onlyPublic: false
			),
			curve: Curve25519.self
		)

		XCTAssertEqual(key.publicKey.rawRepresentation.hex, "3b4fc51ce164be26723264f0a78b7e5ab44a143520c77e0e82bfbb9642e9cfd4")
		let factorSourceID = try FactorSource.id(fromRoot: root, factorSourceKind: .device)
		XCTAssertEqual(factorSourceID.description, "device:6facb00a836864511fdf8f181382209e64e83ad462288ea1bc7868f236fb8033")
	}

	func test_factor_source_id_ledger() throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "equip will roof matter pink blind book anxiety banner elbow sun young",
			language: .english
		)
		let root = try HD.Root(seed: curve25519FactorSourceMnemonic.seed())
		let key = try root.derivePublicKey(
			path: .getID,
			curve: Curve25519.self
		)

		XCTAssertEqual(key.publicKey.rawRepresentation.hex, "e358493920c6f967dc16eff9943fcd5765ab8f42b338ee6769d8ba7f1b9e097f")
		let factorSourceID = try FactorSource.id(fromRoot: root, factorSourceKind: .device)
		XCTAssertEqual(factorSourceID.description, "device:41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0")
	}

	func test_factorSourceID_zoo_zoo__wrong() throws {
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		XCTAssertEqual(try FactorSource.id(fromRoot: mnemonic.hdRoot(), factorSourceKind: .device).description, "device:09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327")
		XCTAssertEqual(try FactorSource.id(fromRoot: mnemonic.hdRoot(passphrase: "foo"), factorSourceKind: .device).description, "device:537b56b9881258f08994392e9858962825d92361b6b4775a3bdfeb4eecc0d069")
	}

	func test_factor_source_id_cap33() async throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "surprise jaguar gloom bring cage obey rotate fiber agree castle rich tomorrow",
			language: .english
		)
		let root = try HD.Root(seed: curve25519FactorSourceMnemonic.seed())
		let key = try root.derivePublicKey(
			path: .init(
				children: [
					.bip44Purpose,
					.coinType,
					.getID,
				],
				onlyPublic: false
			),
			curve: Curve25519.self
		)

		XCTAssertEqual(key.publicKey.rawRepresentation.hex, "156220ef37c5cd3e6da10cdfdba8a0d87ddc4411b4829f60155db3f6bbafc9f8")
		let factorSourceID = try FactorSource.id(fromRoot: root, factorSourceKind: .device)
		XCTAssertEqual(factorSourceID.description, "device:56ee829c02d24487cbe98993f668ff646146e7c9bd02d1815118908c5355d750")
	}

	func test_hdOnDeviceFactorSource() throws {
		let mnemonic = try Mnemonic(
			phrase: "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow",
			language: .english
		)
		let deviceFactorModel: DeviceFactorSource.Hint.Model = "computer"
		let deviceFactorName = "unit test"
		let stableDate = Date.now
		let stableUUID = UUID()
		try withDependencies {
			$0.date = .constant(stableDate)
			$0.uuid = .constant(stableUUID)
		} operation: {
			XCTAssertNoThrow(
				try DeviceFactorSource.olympia(
					mnemonic: mnemonic,
					model: deviceFactorModel,
					name: deviceFactorName,
					addedOn: stableDate
				)
			)
		}
	}
}
