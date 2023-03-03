import Cryptography
import EngineToolkit
import P2PModels
@testable import Profile
import SharedTestingModels
import TestingPrelude

// MARK: - ProfileTests
final class ProfileTests: TestCase {
	let gateway = Gateway.nebunet

	func test_p2p_client_eq() throws {
		let pw = try ConnectionPassword(data: .deadbeef32Bytes)
		let first = P2PClient(connectionPassword: pw, displayName: "first")
		let second = P2PClient(connectionPassword: pw, displayName: "second")
		XCTAssertEqual(first, second)
		var clients = P2PClients(.init())
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
		XCTAssertEqual(factorSourceID.hex(), "4d8b07d0220a9b838b7626dc917b96512abc629bd912a66f60c942fc5fa2f287")
	}

	func test_new_profile() async throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)
		let secp256K1FactorMnemonic = try Mnemonic(
			phrase: "spirit bird issue club alcohol flock skull health lemon judge piece eyebrow",
			language: .english
		)
		let networkID = gateway.network.id
		let babylonFactorSource = try FactorSource.babylon(
			mnemonic: curve25519FactorSourceMnemonic,
			hint: creatingDevice
		)

		var profile = withDependencies {
			$0.uuid = .constant(.init(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!)
		} operation: {
			Profile(factorSource: babylonFactorSource, creatingDevice: creatingDevice)
		}

		let olympiaFactorSource = try FactorSource.olympia(
			mnemonic: secp256K1FactorMnemonic,
			hint: creatingDevice
		)
		profile.factorSources.append(olympiaFactorSource)

		func addNewAccount(_ name: NonEmptyString) throws -> OnNetwork.Account {
			let index = (try? profile.onNetwork(id: networkID))?.accounts.count ?? 0
			let derivationPath = try AccountHierarchicalDeterministicDerivationPath(
				networkID: networkID,
				index: index,
				keyKind: .transactionSigningKey
			)
			let hdRoot = try curve25519FactorSourceMnemonic.hdRoot()

			let publicKey = try hdRoot.derivePublicKey(
				path: .init(
					scheme: .cap26,
					path: derivationPath.derivationPath
				),
				curve: .curve25519
			)

			let address = try OnNetwork.Account.deriveAddress(networkID: networkID, publicKey: publicKey)

			let factorInstance = FactorInstance(
				factorSourceID: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			let account = OnNetwork.Account(
				networkID: networkID,
				address: address,
				securityState: .unsecured(.init(genesisFactorInstance: factorInstance)),
				index: index,
				displayName: name
			)

			try profile.addAccount(account)

			return account
		}

		func addNewPersona(_ name: NonEmptyString, fields: IdentifiedArrayOf<OnNetwork.Persona.Field>) throws -> OnNetwork.Persona {
			let index = (try? profile.onNetwork(id: networkID))?.personas.count ?? 0
			let derivationPath = try IdentityHierarchicalDeterministicDerivationPath(
				networkID: networkID,
				index: index,
				keyKind: .transactionSigningKey
			)
			let hdRoot = try curve25519FactorSourceMnemonic.hdRoot()

			let publicKey = try hdRoot.derivePublicKey(
				path: .init(
					scheme: .cap26,
					path: derivationPath.derivationPath
				),
				curve: .curve25519
			)

			let address = try OnNetwork.Persona.deriveAddress(networkID: networkID, publicKey: publicKey)

			let factorInstance = FactorInstance(
				factorSourceID: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			let persona = OnNetwork.Persona(
				networkID: networkID,
				address: address,
				securityState: .unsecured(.init(genesisFactorInstance: factorInstance)),
				index: index,
				displayName: name,
				fields: fields
			)

			try profile.addPersona(persona)

			return persona
		}

		let firstAccount = try addNewAccount("First")
		XCTAssertEqual(try profile.onNetwork(id: networkID).accounts.count, 1)
		XCTAssertEqual(try profile.onNetwork(id: networkID).accounts.first, firstAccount)
		let secondAccount = try addNewAccount("Second")
		XCTAssertEqual(try profile.onNetwork(id: networkID).accounts.count, 2)
		XCTAssertEqual(try profile.onNetwork(id: networkID).accounts.first, firstAccount)
		XCTAssertEqual(try profile.onNetwork(id: networkID).accounts.last!, secondAccount)

		let thirdAccount = try addNewAccount("Third")

		let firstPersona = try addNewPersona("Mrs Incognito", fields: [
			.init(kind: .firstName, value: "Jane"),
			.init(kind: .lastName, value: "Incognitoson"),
		])
		let secondPersona = try addNewPersona("Mrs Public", fields: [
			.init(kind: .firstName, value: "Maria"),
			.init(kind: .lastName, value: "Publicson"),
		])

		let connectionPassword = try ConnectionPassword(hex: "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")
		XCTAssertNotNil(profile.appendP2PClient(.init(connectionPassword: connectionPassword, displayName: "Brave browser on Mac Studio")))
		// Should not be possible to add a client with the same password
		XCTAssertNil(profile.appendP2PClient(
			P2PClient(
				connectionPassword: connectionPassword,
				displayName: "irrelevant"
			)
		), "Should not be possible to add another P2PClient with same password")

		XCTAssertNotNil(profile.appendP2PClient(
			P2PClient(
				connectionPassword: try! ConnectionPassword(hex: "beefbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadebeef"),
				customWebRTCConfig: .init(peerConnectionConfig: .init(iceServerConfigs: ["example.com", "anotherexample.com"])),
				customSignalingServerConfig: .init(signalingServerBaseURL: URL(string: "custom.signal.com")!),
				customConnectorConfig: .init(reconnectRetryDelay: 3),
				displayName: "iPhone 13",
				platform: .iPhone
			)
		))

		XCTAssertEqual(profile.perNetwork.count, 1)
		let onNetwork = try profile.onNetwork(id: networkID)
		XCTAssertEqual(onNetwork.networkID, networkID)
		XCTAssertEqual(onNetwork.accounts.count, 3)
		XCTAssertEqual(onNetwork.personas.count, 2)

		var authorizedDapp = try profile.addAuthorizedDapp(
			.init(
				networkID: networkID,
				dAppDefinitionAddress: try .init(address: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh"),
				displayName: "RadiSwap",
				referencesToAuthorizedPersonas:
				.init(arrayLiteral:
					.init(
						identityAddress: firstPersona.address,
						fieldIDs: .init(firstPersona.fields.map(\.id)),
						lastLogin: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: try .init(
							accountsReferencedByAddress: [
								secondAccount.address,
								thirdAccount.address,
							],
							forRequest: .exactly(2)
						)
					),
					.init(
						identityAddress: secondPersona.address,
						fieldIDs: .init(secondPersona.fields.map(\.id)),
						lastLogin: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: try .init(
							accountsReferencedByAddress: [
								secondAccount.address,
							],
							forRequest: .atLeast(1)
						)
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

		authorizedDapp.referencesToAuthorizedPersonas[id: authorizedPersona0.id]!.fieldIDs.append(OnNetwork.Persona.Field.ID()) // add unknown fieldID

		XCTAssertThrowsError(try profile.updateAuthorizedDapp(authorizedDapp))

		let snapshot = profile.snapshot()
		let jsonEncoder = JSONEncoder.iso8601
		XCTAssertNoThrow(try jsonEncoder.encode(snapshot))
		/* Uncomment the lines below to generate a new test vector */
		let data = try jsonEncoder.encode(snapshot)
		print(String(data: data, encoding: .utf8)!)
	}

	func test_decode() throws {
		let snapshot: ProfileSnapshot = try readTestFixture(jsonName: "profile_snapshot")

		let profile = try Profile(snapshot: snapshot)
		XCTAssertEqual(profile.creatingDevice, creatingDevice)

		XCTAssertEqual(profile.factorSources.count, 2)
		for factorSource in profile.factorSources {
			XCTAssertEqual(factorSource.hint, creatingDevice)
		}

		XCTAssertEqual(profile.perNetwork.count, 1)
		let networkID = gateway.network.id
		let onNetwork = try profile.perNetwork.onNetwork(id: networkID)
		XCTAssertEqual(onNetwork.accounts.count, 3)

		XCTAssertEqual(onNetwork.accounts[0].networkID, networkID)
		XCTAssertEqual(onNetwork.accounts[0].displayName, "First")
		XCTAssertEqual(onNetwork.accounts[1].displayName, "Second")
		XCTAssertEqual(onNetwork.accounts[2].displayName, "Third")
		XCTAssertEqual(onNetwork.personas[0].networkID, networkID)
		XCTAssertEqual(onNetwork.personas[0].displayName, "Mrs Incognito")
		XCTAssertEqual(onNetwork.personas[1].displayName, "Mrs Public")
		XCTAssertEqual(onNetwork.personas.count, 2)
		XCTAssertEqual(onNetwork.networkID, networkID)

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
			onNetwork.accounts[0].publicKey()?.compressedData.hex(),
			"b9c37926187c6ecfee40577e29942ecc1371c5bb6350288aca92033b16ce595c"
		)

		XCTAssertEqual(
			onNetwork.accounts[0].address.address,
			"account_tdx_b_1pq53vs3xmykn9xx7a80ewt228fszw2cp440u6f69lpyqkrh82f"
		)

		XCTAssertEqual(
			onNetwork.accounts[1].publicKey()?.compressedData.hex(),
			"7c906945cf3d4b4ab27ebf11b6f98e07c506323809f9b501275914f72739ed86"
		)

		XCTAssertEqual(
			onNetwork.accounts[1].address.address,
			"account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu"
		)

		XCTAssertEqual(
			onNetwork.accounts[2].publicKey()?.compressedData.hex(),
			"3f9d3dbae544a46d58703baab5db8d0643879733f7b6e01b39bf96c16ea827d6"
		)

		XCTAssertEqual(
			onNetwork.accounts[2].address.address,
			"account_tdx_b_1pr2q677ep9d5wxnhkkay9c6gvqln6hg3ul006w0a54tshau0z6"
		)

		XCTAssertEqual(
			onNetwork.personas[0].publicKey()?.compressedData.hex(),
			"f361cef2453721ed1b67e4c9266697325766513413de39d19746371466f9f63b"
		)
		XCTAssertEqual(
			onNetwork.personas[0].address.address,
			"identity_tdx_b_1pwvt6shevmzedf0709cgdq0d6axrts5gjfxaws46wdpsedwrfm"
		)

		XCTAssertEqual(
			onNetwork.personas[1].publicKey()?.compressedData.hex(),
			"772ba0ebe12a1637458fefef15299bc57f8e9e21fcf106181d3d780ad1e2bf51"
		)

		XCTAssertEqual(
			onNetwork.personas[1].address.address,
			"identity_tdx_b_1p0vtykvnyhqfamnk9jpnjeuaes9e7f72sekpw6ztqnkshkxgen"
		)

		XCTAssertEqual(profile.appPreferences.p2pClients.clients.count, 2)
		let p2pClient0 = try XCTUnwrap(profile.appPreferences.p2pClients.first)
		XCTAssertEqual(p2pClient0.connectionPassword.hex(), "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")
		let p2pClient1 = profile.appPreferences.p2pClients[1]
		XCTAssertNotNil(p2pClient1.signalingServerConfig)
		XCTAssertNotNil(p2pClient1.webRTCConfig)
		XCTAssertNotNil(p2pClient1.connectorConfig)

		XCTAssertEqual(onNetwork.authorizedDapps.count, 1)
		XCTAssertEqual(onNetwork.authorizedDapps[0].referencesToAuthorizedPersonas.count, 2)
		XCTAssertEqual(onNetwork.authorizedDapps[0].referencesToAuthorizedPersonas[0].fieldIDs.count, 2)
		XCTAssertEqual(onNetwork.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantifier, .exactly)
		XCTAssertEqual(onNetwork.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantity, 2)
		XCTAssertEqual(onNetwork.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.accountsReferencedByAddress.map(\.address), ["account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu", "account_tdx_b_1pr2q677ep9d5wxnhkkay9c6gvqln6hg3ul006w0a54tshau0z6"])
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

private let creatingDevice: NonEmptyString = "computerRunningUnitTest"

extension EntityProtocol {
	func publicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.genesisFactorInstance.publicKey
		}
	}
}
