import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

// MARK: - ProfileTests
final class ProfileTests: TestCase {
	let gateway = Radix.Gateway.nebunet

	func test_p2p_client_eq() throws {
		let pw = try ConnectionPassword(.init(.deadbeef32Bytes))
		let first = P2PLink(connectionPassword: pw, displayName: "first")
		let second = P2PLink(connectionPassword: pw, displayName: "second")
		XCTAssertEqual(first, second)
		var clients = P2PLinks(.init())
		XCTAssertEqual(clients.append(first), first)
		XCTAssertNil(clients.append(second))
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
		let factorSourceID = try FactorSource.id(fromRoot: root)
		XCTAssertEqual(factorSourceID.hex(), "6facb00a836864511fdf8f181382209e64e83ad462288ea1bc7868f236fb8033")
	}

	func test_blake_hash() throws {
		// https://github.com/radixdlt/radixdlt-scrypto/blob/2cdf297f6c7d8e52fd96bb964217a4833306e1ec/radix-engine-common/src/crypto/blake2b.rs#L15-L22
		let digest = try blake2b(data: "Hello Radix".data(using: .utf8)!)
		XCTAssertEqual(digest.hex, "48f1bd08444b5e713db9e14caac2faae71836786ac94d645b00679728202a935")
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
		let factorSourceID = try FactorSource.id(fromRoot: root)
		XCTAssertEqual(factorSourceID.hex(), "41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0")
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
		let factorSourceID = try FactorSource.id(fromRoot: root)
		XCTAssertEqual(factorSourceID.hex(), "56ee829c02d24487cbe98993f668ff646146e7c9bd02d1815118908c5355d750")
	}

	func test_new_profile() async throws {
		continueAfterFailure = false

		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)
		let secp256K1FactorMnemonic = try Mnemonic(
			phrase: "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow",
			language: .english
		)
		let networkID = gateway.network.id

		let (_profile, babylonFactorSource, olympiaFactorSource) = try withDependencies {
			$0.date = .constant(.init(timeIntervalSince1970: 0))
			$0.uuid = .constant(.init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!)
		} operation: {
			let babylonFactorSource = try FactorSource.babylon(
				mnemonic: curve25519FactorSourceMnemonic,
				label: factorSourceLabel,
				description: factorSourceDescription
			)
			let olympiaFactorSource = try FactorSource.olympia(
				mnemonic: secp256K1FactorMnemonic,
				label: factorSourceLabel,
				description: factorSourceDescription
			)
			let profile = Profile(
				factorSource: babylonFactorSource.factorSource,
				creatingDevice: creatingDevice,
				appPreferences: .init(gateways: .init(current: gateway))
			)

			return (profile, babylonFactorSource, olympiaFactorSource)
		}

		var profile = _profile
		XCTAssertEqual(profile.appPreferences.gateways.current.network, gateway.network)
		XCTAssertNil(olympiaFactorSource.factorSource.storage)
		profile.factorSources.append(olympiaFactorSource.factorSource)

		func addNewAccount(_ name: NonEmptyString) throws -> Profile.Network.Account {
			let index = profile.factorSources.babylonDevice.entityCreatingStorage.nextForEntity(
				kind: .account,
				networkID: profile.networkID
			)

			let derivationPath = try AccountBabylonDerivationPath(
				networkID: networkID,
				index: index,
				keyKind: .transactionSigning
			)
			let hdRoot = try curve25519FactorSourceMnemonic.hdRoot()

			let publicKey = try hdRoot.derivePublicKey(
				path: .init(
					scheme: .cap26,
					path: derivationPath.derivationPath
				),
				curve: .curve25519
			)

			let factorInstance = FactorInstance(
				factorSourceID: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			let account = try Profile.Network.Account(
				networkID: networkID,
				factorInstance: factorInstance,
				displayName: name,
				extraProperties: .init(appearanceID: .fromIndex(Int(index)))
			)

			try profile.addAccount(account)

			XCTAssertEqual(profile.network?.networkID, gateway.network.id)
			XCTAssertEqual(profile.network?.networkID, networkID)

			return account
		}

		func addNewPersona(_ name: NonEmptyString, fields: IdentifiedArrayOf<Profile.Network.Persona.Field>) throws -> Profile.Network.Persona {
			let index = profile.factorSources.babylonDevice.entityCreatingStorage.nextForEntity(kind: .identity, networkID: profile.networkID)

			let derivationPath = try IdentityHierarchicalDeterministicDerivationPath(
				networkID: networkID,
				index: index,
				keyKind: .transactionSigning
			)
			let hdRoot = try curve25519FactorSourceMnemonic.hdRoot()

			let publicKey = try hdRoot.derivePublicKey(
				path: .init(
					scheme: .cap26,
					path: derivationPath.derivationPath
				),
				curve: .curve25519
			)

			let factorInstance = FactorInstance(
				factorSourceID: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			let persona = try Profile.Network.Persona(networkID: networkID, factorInstance: factorInstance, displayName: name, extraProperties: .init(fields: fields))

			try profile.addPersona(persona)

			XCTAssertEqual(profile.network?.networkID, gateway.network.id)
			XCTAssertEqual(profile.network?.networkID, networkID)

			return persona
		}

		let firstAccount = try addNewAccount("First")
		XCTAssertEqual(try profile.network(id: networkID).accounts.count, 1)
		XCTAssertEqual(try profile.network(id: networkID).accounts.first, firstAccount)
		let secondAccount = try addNewAccount("Second")
		XCTAssertEqual(try profile.network(id: networkID).accounts.count, 2)
		XCTAssertEqual(try profile.network(id: networkID).accounts.first, firstAccount)
		XCTAssertEqual(try profile.network(id: networkID).accounts.last!, secondAccount)

		let thirdAccount = try addNewAccount("Third")

		let firstPersona = try addNewPersona("Mrs Incognito", fields: [
			.init(id: .givenName, value: "Jane"),
			.init(id: .familyName, value: "Incognitoson"),
		])
		let secondPersona = try addNewPersona("Mrs Public", fields: [
			.init(id: .givenName, value: "Maria"),
			.init(id: .familyName, value: "Publicson"),
		])

		XCTAssertTrue(profile.appPreferences.security.isCloudProfileSyncEnabled, "iCloud sync should be opt-out.")

		let connectionPassword = try ConnectionPassword(.init(hex: "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf"))
		XCTAssertNotNil(profile.appendP2PLink(.init(connectionPassword: connectionPassword, displayName: "Brave browser on Mac Studio")))
		// Should not be possible to add a client with the same password
		XCTAssertNil(profile.appendP2PLink(
			P2PLink(
				connectionPassword: connectionPassword,
				displayName: "irrelevant"
			)
		), "Should not be possible to add another P2PLink with same password")

		XCTAssertNotNil(profile.appendP2PLink(
			P2PLink(
				connectionPassword: try! ConnectionPassword(.init(hex: "beefbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadebeef")),
				displayName: "iPhone 13"
			)
		))

		XCTAssertEqual(profile.networks.count, 1)
		let network = try profile.network(id: networkID)
		XCTAssertEqual(network.networkID, networkID)
		XCTAssertEqual(network.accounts.count, 3)
		XCTAssertEqual(network.personas.count, 2)

		let authorizedDapp = try profile.addAuthorizedDapp(
			.init(
				networkID: networkID,
				dAppDefinitionAddress: .init(address: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh"),
				displayName: "RadiSwap",
				referencesToAuthorizedPersonas:
				.init(arrayLiteral:
					.init(
						identityAddress: firstPersona.address,
						lastLogin: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: .init(
							accountsReferencedByAddress: [
								secondAccount.address,
								thirdAccount.address,
							],
							forRequest: .exactly(2)
						),
						sharedFieldIDs: .init(firstPersona.fields.map(\.id))
					),
					.init(
						identityAddress: secondPersona.address,
						lastLogin: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: .init(
							accountsReferencedByAddress: [
								secondAccount.address,
							],
							forRequest: .atLeast(1)
						),
						sharedFieldIDs: .init(secondPersona.fields.map(\.id))
					))
			)
		)
		let authorizedPersona0 = authorizedDapp.referencesToAuthorizedPersonas[0]
		var authorizedPersona0SharedAccounts = try XCTUnwrap(authorizedPersona0.sharedAccounts)
		XCTAssertThrowsError(
			try authorizedPersona0SharedAccounts.updateAccounts([secondAccount.address]),
			"Should not be able to specify another number of accounts if `exactly` was specified."
		)

		let authorizedPersona1 = authorizedDapp.referencesToAuthorizedPersonas[1]
		var authorizedPersona1SharedAccounts = try XCTUnwrap(authorizedPersona1.sharedAccounts)
		XCTAssertNoThrow(
			try authorizedPersona1SharedAccounts.updateAccounts([
				secondAccount.address,
				thirdAccount.address,
			]), "Should be able to specify more accounts if `atLeast` was specified."
		)

		let snapshot = profile.snapshot()
		let jsonEncoder = JSONEncoder.iso8601
		XCTAssertNoThrow(try jsonEncoder.encode(snapshot))
		// Uncomment the lines below to generate a new test vector
//		let data = try jsonEncoder.encode(snapshot)
//		print(String(data: data, encoding: .utf8)!)
	}

	func test_decode() throws {
		let snapshot: ProfileSnapshot = try readTestFixture(jsonName: "profile_snapshot")

		let profile = try Profile(snapshot: snapshot)
		XCTAssertEqual(profile.creatingDevice, creatingDevice)

		XCTAssertEqual(profile.factorSources.count, 2)
		for factorSource in profile.factorSources {
			XCTAssertEqual(factorSource.label, factorSourceLabel)
			XCTAssertEqual(factorSource.description, factorSourceDescription)
		}
		let deviceFactorSource = profile.factorSources.babylonDevice
		XCTAssertNil(profile.factorSources.last.storage)
		XCTAssertEqual(deviceFactorSource.entityCreatingStorage.nextForEntity(kind: .account, networkID: profile.networkID), 3)
		XCTAssertEqual(deviceFactorSource.entityCreatingStorage.nextForEntity(kind: .identity, networkID: profile.networkID), 2)

		XCTAssertEqual(profile.networks.count, 1)
		let networkID = gateway.network.id
		let network = try profile.networks.network(id: networkID)
		XCTAssertEqual(network.accounts.count, 3)

		XCTAssertEqual(network.accounts[0].networkID, networkID)
		XCTAssertEqual(network.accounts[0].displayName, "First")
		XCTAssertEqual(network.accounts[1].displayName, "Second")
		XCTAssertEqual(network.accounts[2].displayName, "Third")
		XCTAssertEqual(network.personas[0].networkID, networkID)
		XCTAssertEqual(network.personas[0].displayName, "Mrs Incognito")
		XCTAssertEqual(network.personas[1].displayName, "Mrs Public")
		XCTAssertEqual(network.personas.count, 2)
		XCTAssertEqual(network.networkID, networkID)

		XCTAssertTrue(profile.appPreferences.security.isCloudProfileSyncEnabled, "iCloud sync should be opt-out.")
		XCTAssertTrue(profile.appPreferences.security.isDeveloperModeEnabled, "Developer mode should default to on")

		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)
		let secp256K1FactorMnemonic = try Mnemonic(
			phrase: "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow",
			language: .english
		)

		XCTAssertEqual(
			profile.factorSources.first.id,
			try FactorSource.id(fromRoot: curve25519FactorSourceMnemonic.hdRoot())
		)

		XCTAssertEqual(
			profile.factorSources.first(where: { $0.supportsOlympia })!.id,
			try FactorSource.id(fromRoot: secp256K1FactorMnemonic.hdRoot())
		)

		XCTAssertEqual(
			network.accounts[0].publicKey()?.compressedData.hex(),
			"7566e3e948d428112d6c40b597e7ea979b3516dfddc3aa5f51e1316303a09ad3"
		)

		XCTAssertEqual(
			network.accounts[0].address.address,
			"account_tdx_b_1p9dkged3rpzy860ampt5jpmvv3yl4y6f5yppp4tnscdslvt9v3"
		)

		XCTAssertEqual(
			network.accounts[1].publicKey()?.compressedData.hex(),
			"216810705185adf3b8076a60d8d05e9da696ca8e87c1124ea909d394b7433719"
		)

		XCTAssertEqual(
			network.accounts[1].address.address,
			"account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa"
		)

		XCTAssertEqual(
			network.accounts[2].publicKey()?.compressedData.hex(),
			"a82afd5c21188314e60b9045407b7dfad378ba5043bea33b86891f06d94fb1f3"
		)

		XCTAssertEqual(
			network.accounts[2].address.address,
			"account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"
		)

		XCTAssertEqual(
			network.personas[0].publicKey()?.compressedData.hex(),
			"573c0dc84196cb4a7dc8ddff1e92a859c98635a64ef5fe0bcf5c7fe5a7dab3e4"
		)
		XCTAssertEqual(
			network.personas[0].address.address,
			"identity_tdx_b_1pjt9eddph3avjs32wswmk306wgpjelluedsg0hwv928qdunqu8"
		)

		XCTAssertEqual(
			network.personas[1].publicKey()?.compressedData.hex(),
			"6b33fec79f1535ac566b3d840f753942af6447efbe5c50dc343f8ec2122af9b3"
		)

		XCTAssertEqual(
			network.personas[1].address.address,
			"identity_tdx_b_1pshnjvztw6t2hz58jld5mvxvp6ppyjk6ctzu0xhg700scqkhdw"
		)

		XCTAssertEqual(profile.appPreferences.p2pLinks.links.count, 2)
		let p2pLinks0 = try XCTUnwrap(profile.appPreferences.p2pLinks.first)
		XCTAssertEqual(p2pLinks0.connectionPassword.data.hex(), "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")

		XCTAssertEqual(network.authorizedDapps.count, 1)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas.count, 2)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedFieldIDs?.count, 2)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantifier, .exactly)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantity, 2)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.accountsReferencedByAddress.map(\.address), ["account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa", "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"])
	}

	func test_version_compatibility_check_too_low() throws {
		let tooLow = ProfileSnapshot.Version.minimum - 1
		let json = """
		{ "version": \(tooLow) }
		""".data(using: .utf8)!

		XCTAssertThrowsError(
			try ProfileSnapshot.validateVersionCompatibility(ofProfileSnapshotJSONData: json)
		) { anyError in
			guard let error = anyError as? IncompatibleProfileVersion else {
				return XCTFail("WrongErrorType")
			}
			XCTAssertEqual(error, .init(decodedVersion: tooLow, minimumRequiredVersion: .minimum))
		}
	}

	func test_version_compatibility_check_ok() throws {
		let json = """
		{ "version": \(ProfileSnapshot.Version.minimum) }
		""".data(using: .utf8)!

		XCTAssertNoThrow(
			try ProfileSnapshot.validateVersionCompatibility(ofProfileSnapshotJSONData: json)
		)
	}
}

private let factorSourceLabel: FactorSource.Label = "computer"
private let factorSourceDescription: FactorSource.Description = "unit test"
private let creatingDevice: NonEmptyString = "\(factorSourceLabel) \(factorSourceDescription)"

extension EntityProtocol {
	func publicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.transactionSigning.publicKey
		}
	}
}
