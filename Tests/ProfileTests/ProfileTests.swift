import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

// MARK: - ProfileTests
final class ProfileTests: TestCase {
	let gateway = Radix.Gateway.kisharnet

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
		let factorSourceID = try FactorSource.id(fromRoot: root, factorSourceKind: .device)
		XCTAssertEqual(factorSourceID.description, "device:6facb00a836864511fdf8f181382209e64e83ad462288ea1bc7868f236fb8033")
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

	func test_new_profile() async throws {
		continueAfterFailure = false

		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)

		let offDeviceMnemonic = try Mnemonic(
			phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
			language: .english
		)
		let secp256K1FactorMnemonic = try Mnemonic(
			phrase: "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow",
			language: .english
		)
		let networkID = gateway.network.id

		let (_profile, babylonFactorSource, olympiaFactorSource) = try withDependencies {
			$0.date = .constant(stableDate)
			$0.uuid = .constant(stableUUID)
		} operation: {
			let babylonFactorSource = try DeviceFactorSource.babylon(
				mnemonic: curve25519FactorSourceMnemonic,
				model: deviceFactorModel,
				name: deviceFactorName,
				addedOn: stableDate
			)
			let olympiaFactorSource = try DeviceFactorSource.olympia(
				mnemonic: secp256K1FactorMnemonic,
				model: deviceFactorModel,
				name: deviceFactorName,
				addedOn: stableDate
			)

			let profile = Profile(
				header: snapshotHeader,
				deviceFactorSource: babylonFactorSource,
				appPreferences: .init(gateways: .init(current: gateway))
			)

			return (profile, babylonFactorSource, olympiaFactorSource)
		}

		var profile = _profile
		XCTAssertEqual(profile.appPreferences.gateways.current.network, gateway.network)
		profile.factorSources.append(olympiaFactorSource)

		let (trustedContactFactorSource, offDeviceMnemonicFactorSource, ledgerFactorSource) = try withDependencies {
			$0.date = .constant(stableDate)
		} operation: {
			let trustedContactFactorSource = TrustedContactFactorSource.from(
				radixAddress: "account_tdx_c_1px0jul7a44s65568d32f82f0lkssjwx6f5t5e44yl6csqurxw3",
				emailAddress: "hi@rdx.works",
				name: "My friend"
			)
			let offDeviceMnemonicFactorSource = try OffDeviceMnemonicFactorSource.from(mnemonicWithPassphrase: .init(mnemonic: offDeviceMnemonic), label: "Zoo")

			let ledgerFactorSource = try LedgerHardwareWalletFactorSource.model(
				.nanoSPlus,
				name: "Orange",
				deviceID: .deadbeef
			)

			return (trustedContactFactorSource, offDeviceMnemonicFactorSource, ledgerFactorSource)
		}
		profile.factorSources.append(trustedContactFactorSource)
		profile.factorSources.append(offDeviceMnemonicFactorSource)
		profile.factorSources.append(ledgerFactorSource)

		func addNewAccount(_ name: NonEmptyString) throws -> Profile.Network.Account {
			let index = try profile.factorSources.babylonDevice.nextDerivationIndex(
				for: .account,
				networkID: networkID
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

			let factorInstance = HierarchicalDeterministicFactorInstance(
				id: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			var account = try Profile.Network.Account(
				networkID: networkID,
				factorInstance: factorInstance,
				displayName: name,
				extraProperties: .init(appearanceID: .fromIndex(Int(index)))
			)

			if case var .unsecured(control) = account.securityState {
				let path = try derivationPath.switching(keyKind: .authenticationSigning)
				let authPublicKey = try hdRoot.derivePublicKey(
					path: .init(
						scheme: .cap26,
						path: path.derivationPath
					),
					curve: .curve25519
				)

				control.authenticationSigning = HierarchicalDeterministicFactorInstance(
					id: babylonFactorSource.id,
					publicKey: authPublicKey,
					derivationPath: path.wrapAsDerivationPath()
				)
				account.securityState = .unsecured(control)
			}

			try profile.addAccount(account)

			XCTAssertEqual(profile.network?.networkID, gateway.network.id)
			XCTAssertEqual(profile.network?.networkID, networkID)

			return account
		}

		func addNewPersona(
			_ name: NonEmptyString,
			personaData: PersonaData
		) throws -> Profile.Network.Persona {
			let derivationPath = try profile.factorSources.babylonDevice.derivationPath(
				forNext: .identity,
				networkID: profile.networkID
			)
			let hdRoot = try curve25519FactorSourceMnemonic.hdRoot()

			let publicKey = try hdRoot.derivePublicKey(
				path: .init(
					scheme: .cap26,
					path: derivationPath.path
				),
				curve: .curve25519
			)

			let factorInstance = HierarchicalDeterministicFactorInstance(
				id: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath
			)

			var persona = try Profile.Network.Persona(
				networkID: networkID,
				factorInstance: factorInstance,
				displayName: name,
				extraProperties: .init(personaData: personaData)
			)

			if case var .unsecured(control) = persona.securityState {
				let path = try derivationPath.asIdentityPath().switching(keyKind: .authenticationSigning)
				let authPublicKey = try hdRoot.derivePublicKey(
					path: .init(
						scheme: .cap26,
						path: path.derivationPath
					),
					curve: .curve25519
				)

				control.authenticationSigning = HierarchicalDeterministicFactorInstance(
					id: babylonFactorSource.id,
					publicKey: authPublicKey,
					derivationPath: path.wrapAsDerivationPath()
				)
				persona.securityState = .unsecured(control)
			}

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

		let firstPersona = try addNewPersona(
			"Mrs Incognito",
			personaData: .init(
				name: .init(
					id: .init(uuidString: "00000000-0000-0000-0000-000000000000"),
					value: .init(given: "Jane", family: "Incognitoson", variant: .western)
				)
			)
		)
		let secondPersona = try addNewPersona(
			"Mrs Public",
			personaData: .init(
				name: .init(
					id: .init(uuidString: "00000000-0000-0000-0000-000000000001"),
					value: .init(given: "Maria", family: "Publicson", variant: .western)
				)
			)
		)

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
				dAppDefinitionAddress: .init(address: "account_tdx_c_1px0jul7a44s65568d32f82f0lkssjwx6f5t5e44yl6csqurxw3"),
				displayName: "RadiSwap",
				referencesToAuthorizedPersonas:
				.init(arrayLiteral:
					.init(
						identityAddress: firstPersona.address,
						lastLogin: Date(timeIntervalSinceReferenceDate: 0),
						sharedAccounts: .init(
							ids: [
								secondAccount.address,
								thirdAccount.address,
							],
							forRequest: .exactly(2)
						),
//						sharedPersonaData: .init(
//							infoSet: [
//								firstPersona.personaData.entries[0].id,
//							],
//							forRequest: .exactly(1)
//						)
						sharedPersonaData: .init()
					),
					.init(
						identityAddress: secondPersona.address,
						lastLogin: Date(timeIntervalSinceReferenceDate: 0),
						sharedAccounts: .init(
							ids: [
								secondAccount.address,
							],
							forRequest: .atLeast(1)
						),
//						sharedPersonaData: .init(
//							infoSet: [
//								secondPersona.personaData.entries[0].id,
//							],
//							forRequest: .exactly(1)
//						)
						sharedPersonaData: .init()
					))
			)
		)
		let authorizedPersona0 = authorizedDapp.referencesToAuthorizedPersonas[0]
		var authorizedPersona0SharedAccounts = try XCTUnwrap(authorizedPersona0.sharedAccounts)
		XCTAssertThrowsError(
			try authorizedPersona0SharedAccounts.update([secondAccount.address]),
			"Should not be able to specify another number of accounts if `exactly` was specified."
		)

		let authorizedPersona1 = authorizedDapp.referencesToAuthorizedPersonas[1]
		var authorizedPersona1SharedAccounts = try XCTUnwrap(authorizedPersona1.sharedAccounts)
		XCTAssertNoThrow(
			try authorizedPersona1SharedAccounts.update([
				secondAccount.address,
				thirdAccount.address,
			]), "Should be able to specify more accounts if `atLeast` was specified."
		)

		let snapshot = profile.snapshot()
		let jsonEncoder = JSONEncoder.iso8601
		XCTAssertNoThrow(try jsonEncoder.encode(snapshot))
		// Uncomment the lines below to generate a new test vector
		let data = try jsonEncoder.encode(snapshot)
		print(String(data: data, encoding: .utf8)!)
	}

	func test_decode() throws {
		let snapshot: ProfileSnapshot = try readTestFixture(jsonName: "profile_snapshot")

		let profile = try Profile(snapshot: snapshot)
		let date = Date(timeIntervalSince1970: 0)
		let device = ProfileSnapshot.Header.UsedDeviceInfo(
			description: "computer unit test",
			id: .init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!,
			date: date
		)
		let header = ProfileSnapshot.Header(
			creatingDevice: device,
			lastUsedOnDevice: device,
			id: .init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!,
			lastModified: date,
			contentHint: .init(
				numberOfAccountsOnAllNetworksInTotal: 6,
				numberOfPersonasOnAllNetworksInTotal: 3,
				numberOfNetworks: 2
			),
			snapshotVersion: ProfileSnapshot.Header.Version.minimum
		)

		XCTAssertNoDifference(profile.header, header)

		XCTAssertEqual(profile.factorSources.count, 5)
		XCTAssertEqual(Set(profile.factorSources.map(\.kind)), Set([FactorSourceKind.device, .ledgerHQHardwareWallet, .offDeviceMnemonic, .trustedContact]))
		for factorSource in profile.factorSources.compactMap({ $0.extract(DeviceFactorSource.self) }) {
			XCTAssertEqual(factorSource.hint.name, deviceFactorName)
			XCTAssertEqual(factorSource.hint.model, deviceFactorModel)
		}
		let deviceFactorSource = profile.factorSources.babylonDevice
		XCTAssertEqual(try deviceFactorSource.nextDerivationIndex(for: .account, networkID: profile.networkID), 3)
		XCTAssertEqual(try deviceFactorSource.nextDerivationIndex(for: .identity, networkID: profile.networkID), 2)

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
			try FactorSource.id(fromRoot: curve25519FactorSourceMnemonic.hdRoot(), factorSourceKind: .device).embed()
		)

		XCTAssertEqual(
			profile.factorSources.first(where: { $0.supportsOlympia })!.id,
			try FactorSource.id(fromRoot: secp256K1FactorMnemonic.hdRoot(), factorSourceKind: .device).embed()
		)

		// Account 0
		XCTAssertEqual(
			network.accounts[0].publicKey()?.compressedData.hex(),
			"229c2acaeba87f5231390bfde38da4f4e9f84ab90fb77658aea7983a7af6741d"
		)

		XCTAssertEqual(
			network.accounts[0].authPublicKey()?.compressedData.hex(),
			"042f0f24e62932483972b4ff07d63963990e5d7952305babf8014523d65c2b38"
		)

		XCTAssertEqual(
			network.accounts[0].address.address,
			"account_tdx_c_1pyezed90u5qtagu2247rqw7f04vc7wnhsfjz4nf6vuvqtj9kcq"
		)

		// Account 1
		XCTAssertEqual(
			network.accounts[1].publicKey()?.compressedData.hex(),
			"150a73661bfae1e6aad771d47bef2b20a92925fcaee3e49762872b2af191b3e7"
		)
		XCTAssertEqual(
			network.accounts[1].authPublicKey()?.compressedData.hex(),
			"82a8ebf9216cef03592ba6d798d67159e154c41b3f2d8d22faf3f4f9b1a5c859"
		)

		XCTAssertEqual(
			network.accounts[1].address.address,
			"account_tdx_c_1p82arz264ntf727q2s7f7cm6pqucgqzuru3z7mgeg3gqua0wlj"
		)

		// Account 2
		XCTAssertEqual(
			network.accounts[2].publicKey()?.compressedData.hex(),
			"5cc3c64b1d155494bcf03bf607e0fa4aa8c86fca796d7cafc4f88c24d109fc01"
		)
		XCTAssertEqual(
			network.accounts[2].authPublicKey()?.compressedData.hex(),
			"ee4565de7dd845d21fece2579bb1cf8c977dbf03408240d63ad11e53a2aa3bd5"
		)

		XCTAssertEqual(
			network.accounts[2].address.address,
			"account_tdx_c_1pygfwtlv7l90rcsge6t0f0jwn3cuzp05y8geek45qw7s98msmw"
		)

		// Persona 0
		XCTAssertEqual(
			network.personas[0].publicKey()?.compressedData.hex(),
			"e8b6f865cf2696442ba3106550b3e55d8c65c181066d76f49138306d101d0db7"
		)
		XCTAssertEqual(
			network.personas[0].authPublicKey()?.compressedData.hex(),
			"bac131975cc66651961835490731f321f70289c306dfae52652cbad44a3647c7"
		)

		XCTAssertEqual(
			network.personas[0].address.address,
			"identity_tdx_c_1pntzwn92848tkaatj4psmgtuvsn83lnknku6av34alxqdrsvjv"
		)

		// Persona 1
		XCTAssertEqual(
			network.personas[1].publicKey()?.compressedData.hex(),
			"873a41469982a92b52ecb9e5ef6d8267db306b3143efd50d220f867bc3403c22"
		)
		XCTAssertEqual(
			network.personas[1].authPublicKey()?.compressedData.hex(),
			"20a16f3d5df0fb8ebb34fa08edb5143a154c55e857fb5c2273366b8c716ca740"
		)

		XCTAssertEqual(
			network.personas[1].address.address,
			"identity_tdx_c_1p30wtkl76qpyenu88sverfdh0qwf70gulgu29k72myqq2hqg0r"
		)

		XCTAssertEqual(profile.appPreferences.p2pLinks.links.count, 2)
		let p2pLinks0 = try XCTUnwrap(profile.appPreferences.p2pLinks.first)
		XCTAssertEqual(p2pLinks0.connectionPassword.data.hex(), "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")

		XCTAssertEqual(network.authorizedDapps.count, 1)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas.count, 2)

		XCTAssertNotNil(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedPersonaData.name)

		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantifier, .exactly)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantity, 2)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.ids.map(\.address), ["account_tdx_c_1p82arz264ntf727q2s7f7cm6pqucgqzuru3z7mgeg3gqua0wlj", "account_tdx_c_1pygfwtlv7l90rcsge6t0f0jwn3cuzp05y8geek45qw7s98msmw"])
	}

	func test_version_compatibility_check_too_low() throws {
		let tooLow = ProfileSnapshot.Header.Version.minimum - 1

		let oldHeader = ProfileSnapshot.Header(
			creatingDevice: device,
			lastUsedOnDevice: device,
			id: stableUUID,
			lastModified: stableDate,
			contentHint: .init(),
			snapshotVersion: tooLow
		)
		XCTAssertThrowsError(
			try oldHeader.validateCompatibility()
		) { anyError in
			guard let error = anyError as? ProfileSnapshot.Header.IncompatibleProfileVersion else {
				return XCTFail("WrongErrorType")
			}
			XCTAssertEqual(error, .init(decodedVersion: tooLow, minimumRequiredVersion: .minimum))
		}
	}

	func test_version_compatibility_check_ok() throws {
		XCTAssertNoThrow(
			try snapshotHeader.validateCompatibility()
		)
	}
}

private let deviceFactorModel: DeviceFactorSource.Hint.Model = "computer"
private let deviceFactorName: String = "unit test"
private let creatingDevice: NonEmptyString = "\(deviceFactorModel) \(deviceFactorName)"
private let stableDate = Date(timeIntervalSince1970: 0)
private let stableUUID = UUID(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!
private let device: ProfileSnapshot.Header.UsedDeviceInfo = .init(description: creatingDevice, id: stableUUID, date: stableDate)
private let snapshotHeader = ProfileSnapshot.Header(
	creatingDevice: device,
	lastUsedOnDevice: device,
	id: stableUUID,
	lastModified: stableDate,
	contentHint: .init(
		numberOfAccountsOnAllNetworksInTotal: 6,
		numberOfPersonasOnAllNetworksInTotal: 3,
		numberOfNetworks: 2
	),
	snapshotVersion: .minimum
)

extension EntityProtocol {
	func publicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.transactionSigning.publicKey
		}
	}

	func authPublicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.authenticationSigning?.publicKey
		}
	}
}

extension DeviceFactorSource {
	public static func babylon(
		mnemonic: Mnemonic,
		model: Hint.Model,
		name: String,
		addedOn: Date
	) throws -> Self {
		try Self.babylon(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}

	public static func olympia(
		mnemonic: Mnemonic,
		model: Hint.Model,
		name: String,
		addedOn: Date
	) throws -> Self {
		try Self.olympia(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}
}

// MARK: - EmailAddress + ExpressibleByStringLiteral
extension EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		let nonEmpty = NonEmptyString(rawValue: value)!
		try! self.init(validating: nonEmpty)
	}
}

// MARK: - AccountAddress + ExpressibleByStringLiteral
extension AccountAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		try! self.init(address: value)
	}
}
