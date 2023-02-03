import Cryptography
import EngineToolkit
import P2PModels
@testable import Profile
import SharedTestingModels
import TestingPrelude

// MARK: - ProfileTests
final class ProfileTests: TestCase {
	let networkAndGateway = AppPreferences.NetworkAndGateway.nebunet

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
		let networkID = networkAndGateway.network.id
		var profile = try await Profile.new(
			networkAndGateway: networkAndGateway,
			mnemonic: curve25519FactorSourceMnemonic,
			accountCreationStrategy: .createAccountOnDefaultNetwork(named: .init(rawValue: "First")!)
		)

		let secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource = try Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(
			mnemonic: secp256K1FactorMnemonic
		)

		XCTAssertNotNil(
			profile.addFactorSource(secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource)
		)

		let deviceFactorSource = try Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(
			mnemonic: curve25519FactorSourceMnemonic
		)

		let createFactorInstance: CreateFactorInstanceForRequest = { createFactorInstanceRequest in

			// used by some tests below
			let includePrivateKey = true

			switch createFactorInstanceRequest {
			case let .fromNonHardwareHierarchicalDeterministicMnemonicFactorSource(nonHWHDRequest):
				if nonHWHDRequest.reference == deviceFactorSource.reference {
					return try await deviceFactorSource.createAnyFactorInstanceForResponse(
						input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput(
							mnemonic: curve25519FactorSourceMnemonic,
							derivationPath: nonHWHDRequest.derivationPath,
							includePrivateKey: includePrivateKey
						)
					)
				} else if nonHWHDRequest.reference == secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource.reference {
					return try await secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource
						.createAnyFactorInstanceForResponse(
							input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput(
								mnemonic: secp256K1FactorMnemonic,
								derivationPath: nonHWHDRequest.derivationPath,
								includePrivateKey: includePrivateKey
							)
						)
				} else {
					XCTFail("unknown factor source")
					return nil
				}
			}
		}

		let secondAccount = try await profile.createNewVirtualAccount(
			networkID: networkID,
			displayName: "Second",
			createFactorInstance: createFactorInstance
		)

		func doTest(signerOf: SignersOf<OnNetwork.Account>) async throws {
			let testMessage = Data(SHA256.twice(data: "test".data(using: .utf8)!))
			XCTAssertEqual(signerOf.entity, secondAccount)
			let signatureOfSigner = try await signerOf.notarySigner(testMessage)
			XCTAssertEqual(signatureOfSigner.publicKey.compressedRepresentation.hex, "7c906945cf3d4b4ab27ebf11b6f98e07c506323809f9b501275914f72739ed86")
			XCTAssertTrue(signatureOfSigner.publicKey.isValidSignature(signatureOfSigner.signature, for: testMessage))
		}

		let mnemonicForFactorSourceByReference: MnemonicForFactorSourceByReference = { _ in
			curve25519FactorSourceMnemonic
		}

		var signerOf = try await profile.signers(of: secondAccount, mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference).first
		try await doTest(signerOf: signerOf)
		signerOf = try await profile.signers(networkID: networkID, entityType: OnNetwork.Account.self, entityIndex: 1, mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference).first
		try await doTest(signerOf: signerOf)
		signerOf = try await profile.signers(networkID: networkID, address: secondAccount.address, mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference).first
		try await doTest(signerOf: signerOf)

		let thirdAccount = try await profile.createNewVirtualAccount(
			networkID: networkID,
			displayName: "Third",
			createFactorInstance: createFactorInstance
		)

		let persona0 = try await profile.createNewVirtualPersona(
			networkID: networkID,
			displayName: "Mrs Incognito",
			fields: [
				.init(kind: .firstName, value: "Jane"),
				.init(kind: .lastName, value: "Incognitoson"),
			],
			createFactorInstance: createFactorInstance
		)

		let persona1 = try await profile.createNewVirtualPersona(
			networkID: networkID,
			displayName: "Mrs Public",
			fields: [
				.init(kind: .firstName, value: "Maria"),
				.init(kind: .lastName, value: "Publicson"),
			],
			createFactorInstance: createFactorInstance
		)

		let connectionPassword = try ConnectionPassword(hex: "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")

		XCTAssertNotNil(profile.appendP2PClient(
			P2PClient(
				connectionPassword: connectionPassword,
				displayName: "Brave browser on Mac Studio"
			)
		))

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

		var connectedDapp = try await profile.addConnectedDapp(
			.init(
				networkID: networkID,
				dAppDefinitionAddress: try .init(address: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh"),
				displayName: "RadiSwap",
				referencesToAuthorizedPersonas:
				.init(arrayLiteral:
					.init(
						identityAddress: persona0.address,
						fieldIDs: .init(persona0.fields.map(\.id)),
						lastLoginDate: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: try .init(
							mode: .exactly(.init(
								arrayLiteral:
								secondAccount.address,
								thirdAccount.address
							))
						)
					),
					.init(
						identityAddress: persona1.address,
						fieldIDs: .init(persona1.fields.map(\.id)),
						lastLoginDate: Date(timeIntervalSinceReferenceDate: 0), // FIXME: @Nikola
						sharedAccounts: try .init(
							mode: .atLeast(.init(
								arrayLiteral:
								secondAccount.address
							))
						)
					))
			)
		)

		var authorizedPersona0 = connectedDapp.referencesToAuthorizedPersonas[0]
		XCTAssertThrowsError(
			try authorizedPersona0.sharedAccounts.updateAccounts(.init(
				arrayLiteral:
				secondAccount.address
			)), "Should not be able to specify another number of accounts if `exactly` was specified."
		)

		var authorizedPersona1 = connectedDapp.referencesToAuthorizedPersonas[1]
		XCTAssertNoThrow(
			try authorizedPersona1.sharedAccounts.updateAccounts(.init(
				arrayLiteral:
				secondAccount.address,
				thirdAccount.address
			)), "Should be able to specify more accounts if `atLeast` was specified."
		)

		connectedDapp.referencesToAuthorizedPersonas[id: authorizedPersona0.id]!.fieldIDs.append(OnNetwork.Persona.Field.ID()) // add unknown fieldID

		// Cannot use `XCTAssertThrowsError` since it does not accept async code
		// => fallback to `do catch`
		do {
			try await profile.updateConnectedDapp(connectedDapp)
			XCTFail("No error was thrown, but we expected `updateConnectedDapp` to have failed because ConnectedDapp was invalid")
		} catch {
			// All good, we expected error
		}

		let snapshot = profile.snaphot()
		let jsonEncoder = JSONEncoder.iso8601
		XCTAssertNoThrow(try jsonEncoder.encode(snapshot))
		let data = try jsonEncoder.encode(snapshot)
		/* Uncomment to generate a new test vector */
		print(String(data: data, encoding: .utf8)!)
	}

	func test_decode() throws {
		let snapshot: ProfileSnapshot = try readTestFixture(jsonName: "profile_snapshot")

		let profile = try Profile(snapshot: snapshot)

		XCTAssertEqual(profile.factorSources.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.count, 1)
		XCTAssertEqual(profile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.rawValue.count, 1)

		XCTAssertEqual(profile.perNetwork.count, 1)
		let networkID = networkAndGateway.network.id
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
			profile
				.factorSources
				.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources
				.first
				.factorSourceID,

			try HD.Root(
				seed: curve25519FactorSourceMnemonic.seed()
			).factorSourceID(curve: Curve25519.self)
		)

		XCTAssertEqual(
			profile.factorSources.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.first!.factorSourceID
				.rawValue
				.hex(),

			try HD.Root(seed: secp256K1FactorMnemonic.seed())
				.factorSourceID(curve: SECP256K1.self)
				.rawValue
				.hex()
		)

		XCTAssertEqual(
			onNetwork.accounts[0].publicKey()?.compressedData.hex(),
			"b9c37926187c6ecfee40577e29942ecc1371c5bb6350288aca92033b16ce595c"
		)

		XCTAssertEqual(
			onNetwork.accounts[0].address.address,
			"account_tdx_b_1qu53vs3xmykn9xx7a80ewt228fszw2cp440u6f69lpyqt2xqvl"
		)

		XCTAssertEqual(
			onNetwork.accounts[1].publicKey()?.compressedData.hex(),
			"7c906945cf3d4b4ab27ebf11b6f98e07c506323809f9b501275914f72739ed86"
		)

		XCTAssertEqual(
			onNetwork.accounts[1].address.address,
			"account_tdx_b_1qavvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqxgpf32"
		)

		XCTAssertEqual(
			onNetwork.accounts[2].publicKey()?.compressedData.hex(),
			"3f9d3dbae544a46d58703baab5db8d0643879733f7b6e01b39bf96c16ea827d6"
		)

		XCTAssertEqual(
			onNetwork.accounts[2].address.address,
			"account_tdx_b_1ql2q677ep9d5wxnhkkay9c6gvqln6hg3ul006w0a54ts25dgyv"
		)

		XCTAssertEqual(
			onNetwork.personas[0].publicKey()?.compressedData.hex(),
			"f361cef2453721ed1b67e4c9266697325766513413de39d19746371466f9f63b"
		)
		XCTAssertEqual(
			onNetwork.personas[0].address.address,
			"account_tdx_b_1q7vt6shevmzedf0709cgdq0d6axrts5gjfxaws46wdpskvpcn0"
		)

		XCTAssertEqual(
			onNetwork.personas[1].publicKey()?.compressedData.hex(),
			"772ba0ebe12a1637458fefef15299bc57f8e9e21fcf106181d3d780ad1e2bf51"
		)

		XCTAssertEqual(
			onNetwork.personas[1].address.address,
			"account_tdx_b_1qlvtykvnyhqfamnk9jpnjeuaes9e7f72sekpw6ztqnkschfnr8"
		)

		XCTAssertEqual(profile.appPreferences.p2pClients.clients.count, 2)
		let p2pClient0 = try XCTUnwrap(profile.appPreferences.p2pClients.first)
		XCTAssertEqual(p2pClient0.connectionPassword.hex(), "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")
		let p2pClient1 = profile.appPreferences.p2pClients[1]
		XCTAssertNotNil(p2pClient1.signalingServerConfig)
		XCTAssertNotNil(p2pClient1.webRTCConfig)
		XCTAssertNotNil(p2pClient1.connectorConfig)

		XCTAssertEqual(onNetwork.connectedDapps.count, 1)
		XCTAssertEqual(onNetwork.connectedDapps[0].referencesToAuthorizedPersonas.count, 2)
		XCTAssertEqual(onNetwork.connectedDapps[0].referencesToAuthorizedPersonas[0].fieldIDs.count, 2)
		XCTAssertEqual(onNetwork.connectedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts.mode, .exactly)
		XCTAssertEqual(onNetwork.connectedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts.accountsReferencedByAddress.map(\.address), ["account_tdx_b_1qavvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqxgpf32", "account_tdx_b_1ql2q677ep9d5wxnhkkay9c6gvqln6hg3ul006w0a54ts25dgyv"])
	}

	func test_version_compatability_check_too_low() throws {
		let json = """
		{ "version": 7 }
		""".data(using: .utf8)!

		XCTAssertThrowsError(
			try ProfileSnapshot.validateVersionCompatability(ofProfileSnapshotJSONData: json)
		) { anyError in
			guard let error = anyError as? IncompatibleProfileVersion else {
				return XCTFail("WrongErrorType")
			}
			XCTAssertEqual(error, .init(decodedVersion: 7, minimumRequiredVersion: .minimum))
		}
	}

	func test_version_compatability_check_ok() throws {
		let json = """
		{ "version": \(ProfileSnapshot.Version.minimum) }
		""".data(using: .utf8)!

		XCTAssertNoThrow(
			try ProfileSnapshot.validateVersionCompatability(ofProfileSnapshotJSONData: json)
		)
	}
}

extension EntityProtocol {
	func publicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			guard let hdFactorInstance = control.genesisFactorInstance.any() as? (any FactorInstanceHierarchicalDeterministicProtocol) else {
				return nil
			}
			return hdFactorInstance.publicKey
		}
	}
}
