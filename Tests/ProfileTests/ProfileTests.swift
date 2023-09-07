import Cryptography

import EngineKit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

// MARK: - ProfileTests
final class ProfileTests: TestCase {
	let gateway = Radix.Gateway.default

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

	// FIXME: Rewrite this whole test... which manually populates profile instead of using our production code!
	func test_generate_profile_snapshot_test_vector() async throws {
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
				header: .init(
					creatingDevice: device,
					lastUsedOnDevice: device,
					id: stableUUID,
					lastModified: stableDate,
					// FIXME: we should not hard code these... actually we should rewrite this whole test... which manually populates profile instead of using our production code!
					contentHint: .init(
						numberOfAccountsOnAllNetworksInTotal: 3,
						numberOfPersonasOnAllNetworksInTotal: 2,
						numberOfNetworks: 1
					),
					snapshotVersion: .minimum
				),
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
				radixAddress: "account_rdx1283u6e8r2jnz4a3jwv0hnrqfr5aq50yc9ts523sd96hzfjxqqcs89q",
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

		func addNewAccount(
			_ name: NonEmptyString,
			makeThirdPartyDeposit: (() throws -> Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits)? = nil
		) throws -> Profile.Network.Account {
			let _index: Int = {
				do {
					return try profile.network(id: networkID).accounts.count
				} catch {
					return 0
				}
			}()
			let index = HD.Path.Component.Child.Value(_index)

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
				index: index,
				factorInstance: factorInstance,
				displayName: name,
				extraProperties: .init(appearanceID: .fromIndex(Int(index)))
			)

			if let makeThirdPartyDeposit {
				try account.onLedgerSettings.thirdPartyDeposits = makeThirdPartyDeposit()
			}

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
			let _index: Int = {
				do {
					return try profile.network(id: networkID).personas.count
				} catch {
					return 0
				}
			}()
			let index = HD.Path.Component.Child.Value(_index)

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

			let factorInstance = HierarchicalDeterministicFactorInstance(
				id: babylonFactorSource.id,
				publicKey: publicKey,
				derivationPath: derivationPath.wrapAsDerivationPath()
			)

			var persona = try Profile.Network.Persona(
				networkID: networkID,
				index: index,
				factorInstance: factorInstance,
				displayName: name,
				extraProperties: .init(personaData: personaData)
			)

			if case var .unsecured(control) = persona.securityState {
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
		let secondAccount = try addNewAccount("Second") {
			try .init(
				depositRule: .acceptKnown,
				assetsExceptionList: [
					.init(
						address: .init(validatingAddress: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder"),
						exceptionRule: .deny
					),
				],
				depositorsAllowList: [
					.resourceAddress(.init(validatingAddress: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")),
					.nonFungibleGlobalID(.init(nonFungibleGlobalId: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder:#2#")),
				]
			)
		}
		XCTAssertEqual(try profile.network(id: networkID).accounts.count, 2)
		XCTAssertEqual(try profile.network(id: networkID).accounts.first, firstAccount)
		XCTAssertEqual(try profile.network(id: networkID).accounts.last!, secondAccount)

		let thirdAccount = try addNewAccount("Third") {
			try .init(
				depositRule: .denyAll,
				assetsExceptionList: [
					.init(
						address: .init(validatingAddress: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder"),
						exceptionRule: .allow
					),
				],
				depositorsAllowList: [
					.resourceAddress(.init(validatingAddress: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")),
					.nonFungibleGlobalID(.init(nonFungibleGlobalId: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder:#2#")),
				]
			)
		}

		let firstPersona = try withDependencies {
			$0.uuid = .incrementing
		} operation: {
			try addNewPersona(
				"Satoshi",
				personaData: .previewValue
			)
		}

		let secondPersona = try addNewPersona(
			"Mrs Public",
			personaData: .init(
				name: .init(
					id: .init(uuidString: "00000000-0000-0000-0000-0000000000FF")!,
					value: .init(variant: .western, familyName: "Publicson", givenNames: "Maria", nickname: "Publy")
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
				dAppDefinitionAddress: .init(validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q"),
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
						sharedPersonaData: .init(personaData: firstPersona.personaData)
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
						sharedPersonaData: .init(
							name: secondPersona.personaData.name?.id
						)
					))
			)
		)
		let authorizedPersona0 = authorizedDapp.referencesToAuthorizedPersonas[0]
		var authorizedPersona0SharedAccounts: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts = try XCTUnwrap(authorizedPersona0.sharedAccounts)
		XCTAssertThrowsError(
			try authorizedPersona0SharedAccounts.update([secondAccount.address]),
			"Should not be able to specify another number of accounts if `exactly` was specified."
		)

		let authorizedPersona1 = authorizedDapp.referencesToAuthorizedPersonas[1]
		var authorizedPersona1SharedAccounts: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts = try XCTUnwrap(authorizedPersona1.sharedAccounts)
		XCTAssertNoThrow(
			try authorizedPersona1SharedAccounts.update([
				secondAccount.address,
				thirdAccount.address,
			]), "Should be able to specify more accounts if `atLeast` was specified."
		)

		let snapshot = profile.snapshot()

		XCTAssertEqual(snapshot.networks.count, snapshot.header.contentHint.numberOfNetworks)
		XCTAssertEqual(snapshot.header.contentHint.numberOfAccountsOnAllNetworksInTotal, profile.network?.accounts.count)
		XCTAssertEqual(snapshot.header.contentHint.numberOfPersonasOnAllNetworksInTotal, profile.network?.personas.count)
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
				numberOfAccountsOnAllNetworksInTotal: 3,
				numberOfPersonasOnAllNetworksInTotal: 2,
				numberOfNetworks: 1
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

		XCTAssertEqual(profile.networks.count, 1)
		let networkID = gateway.network.id
		let network = try profile.networks.network(id: networkID)
		XCTAssertEqual(network.accounts.count, 3)

		XCTAssertEqual(network.accounts[0].networkID, networkID)
		XCTAssertEqual(network.accounts[0].displayName, "First")
		XCTAssertEqual(network.accounts[1].displayName, "Second")
		XCTAssertEqual(network.accounts[2].displayName, "Third")
		XCTAssertEqual(network.personas[0].networkID, networkID)
		XCTAssertEqual(network.personas[0].displayName, "Satoshi")

		withDependencies {
			$0.uuid = .incrementing
		} operation: {
			XCTAssertEqual(network.personas[0].personaData, .previewValue)
		}

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
			"390f5d05f6f4ce18a5a049e713ad098773b7cc0ca0c530c6422742579633f9b8"
		)

		XCTAssertEqual(
			network.accounts[0].authPublicKey()?.compressedData.hex(),
			"920847d21c0db9f3d04e8f80ec6e8c3657404c38089f0673d9b14da5e40906e4"
		)

		XCTAssertEqual(
			network.accounts[0].address.address,
			"account_tdx_22_128aph4j6zjqzhslfwqvryx829dwfxfflh0vamyca3425f78uul5rxf"
		)

		XCTAssertEqual(
			network.accounts[0].onLedgerSettings,
			.init(thirdPartyDeposits: .init(
				depositRule: .acceptAll,
				assetsExceptionList: [],
				depositorsAllowList: []
			)
			)
		)

		// Account 1
		XCTAssertEqual(
			network.accounts[1].publicKey()?.compressedData.hex(),
			"fe12a293195513e2f0dc326521ef08a78e3ae743e34c46228bb231cc2e96dac8"
		)
		XCTAssertEqual(
			network.accounts[1].authPublicKey()?.compressedData.hex(),
			"6d0fff607c4a1da5bd363aa93263680527b5dea0fad7c96fae9e29b9ce649e1d"
		)

		XCTAssertEqual(
			network.accounts[1].address.address,
			"account_tdx_22_12yktr4z690lpn874q2zrdggqrjrcqp0zynx629kxy4gfufzw23d3f6"
		)

		XCTAssertEqual(
			network.accounts[1].onLedgerSettings.thirdPartyDeposits.depositRule, .acceptKnown
		)

		XCTAssertEqual(
			network.accounts[1].onLedgerSettings.thirdPartyDeposits.assetsExceptionList[0].address,
			.init(stringLiteral: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")
		)
		XCTAssertEqual(
			network.accounts[1].onLedgerSettings.thirdPartyDeposits.assetsExceptionList[0].exceptionRule, .deny
		)

		XCTAssertEqual(
			network.accounts[1].onLedgerSettings.thirdPartyDeposits.depositorsAllowList,
			try [
				.resourceAddress(.init(stringLiteral: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")),
				.nonFungibleGlobalID(.init(nonFungibleGlobalId: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder:#2#")),
			]
		)

		// Account 2
		XCTAssertEqual(
			network.accounts[2].publicKey()?.compressedData.hex(),
			"16220c8187c43a82ebba61b2428370c6816f05e6417190185f22bb5ed214fbdf"
		)
		XCTAssertEqual(
			network.accounts[2].authPublicKey()?.compressedData.hex(),
			"4cc7fee56f3688d75a694ced33f41364ef94fc3ac2415a5ef7a0d699faa45ef5"
		)

		XCTAssertEqual(
			network.accounts[2].address.address,
			"account_tdx_22_12ya2hy3wsmrm88svkeugan753f5atlhk3dzz09n9gm46qvx69rjqcm"
		)

		XCTAssertEqual(
			network.accounts[2].onLedgerSettings.thirdPartyDeposits.depositRule, .denyAll
		)

		XCTAssertEqual(
			network.accounts[2].onLedgerSettings.thirdPartyDeposits.assetsExceptionList[0].address,
			.init(stringLiteral: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")
		)
		XCTAssertEqual(
			network.accounts[2].onLedgerSettings.thirdPartyDeposits.assetsExceptionList[0].exceptionRule, .allow
		)

		XCTAssertEqual(
			network.accounts[2].onLedgerSettings.thirdPartyDeposits.depositorsAllowList,
			try [
				.resourceAddress(.init(stringLiteral: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder")),
				.nonFungibleGlobalID(.init(nonFungibleGlobalId: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder:#2#")),
			]
		)

		// Persona 0
		XCTAssertEqual(
			network.personas[0].publicKey()?.compressedData.hex(),
			"cb5f31fee2b66013a6476bd4bf37bf6bf229404a6db1567db317ed0ba5334358"
		)
		XCTAssertEqual(
			network.personas[0].authPublicKey()?.compressedData.hex(),
			"55ad07a9e836ead171cdb3b1d62fe5405d89dcb42559fb67f6851f5438e98859"
		)

		XCTAssertEqual(
			network.personas[0].address.address,
			"identity_tdx_22_12g5xajl295tda2vym7tqtw4l5ftssp97fe5j9ga9wqpy7hjpe8ncmn"
		)

		// Persona 1
		XCTAssertEqual(
			network.personas[1].publicKey()?.compressedData.hex(),
			"8620fd68dd9c594ff2477ee17189d32d79751915b21aa43e3f19b72a2f4404e3"
		)
		XCTAssertEqual(
			network.personas[1].authPublicKey()?.compressedData.hex(),
			"9ba8a618d9f3f6fac1e5a8067193bef5d64f94ad13ec0af1fcb4095f953ff836"
		)

		XCTAssertEqual(
			network.personas[1].address.address,
			"identity_tdx_22_12tmdjpyjwr8qk2fpvzk655cga5jl54f8lzn570wga6wmfl3aulu5ju"
		)

		XCTAssertEqual(profile.appPreferences.p2pLinks.links.count, 2)
		let p2pLinks0 = try XCTUnwrap(profile.appPreferences.p2pLinks.first)
		XCTAssertEqual(p2pLinks0.connectionPassword.data.hex(), "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf")

		XCTAssertEqual(network.authorizedDapps.count, 1)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas.count, 2)

		XCTAssertNotNil(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedPersonaData.name)

		let reconstructedSharedPersonaData = try network.detailsForAuthorizedDapp(network.authorizedDapps[0]).detailedAuthorizedPersonas[0].sharedPersonaData

		withDependencies {
			$0.uuid = .incrementing
		} operation: {
			let expectedPersonaData = PersonaData.previewValue
			XCTAssertEqual(reconstructedSharedPersonaData, expectedPersonaData)
		}

		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantifier, .exactly)
		XCTAssertEqual(network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.request.quantity, 2)
		XCTAssertEqual(
			network.authorizedDapps[0].referencesToAuthorizedPersonas[0].sharedAccounts?.ids.map(\.address),
			[
				"account_tdx_22_12yktr4z690lpn874q2zrdggqrjrcqp0zynx629kxy4gfufzw23d3f6",
				"account_tdx_22_12ya2hy3wsmrm88svkeugan753f5atlhk3dzz09n9gm46qvx69rjqcm",
			]
		)
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
		let snapshotHeader = ProfileSnapshot.Header(
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
		try babylon(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}

	public static func olympia(
		mnemonic: Mnemonic,
		model: Hint.Model,
		name: String,
		addedOn: Date
	) throws -> Self {
		try olympia(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}
}

// MARK: - EmailAddress + ExpressibleByStringLiteral
extension EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		let nonEmpty = NonEmptyString(rawValue: value)!
		try! self.init(validating: nonEmpty)
	}
}

// MARK: - SpecificAddress + ExpressibleByStringLiteral
extension SpecificAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		try! self.init(validatingAddress: value)
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData {
	init(personaData: PersonaData) throws {
		try self.init(
			name: personaData.name?.id,
			dateOfBirth: personaData.dateOfBirth?.id,
			companyName: personaData.companyName?.id,
			emailAddresses: .init(ids: .init(validating: personaData.emailAddresses.map(\.id)), forRequest: .atLeast(1)),
			phoneNumbers: .init(ids: .init(validating: personaData.phoneNumbers.map(\.id)), forRequest: .atLeast(1)),
			urls: .init(ids: .init(validating: personaData.urls.map(\.id)), forRequest: .atLeast(1)),
			postalAddresses: .init(ids: .init(validating: personaData.postalAddresses.map(\.id)), forRequest: .atLeast(1)),
			creditCards: .init(ids: .init(validating: personaData.creditCards.map(\.id)), forRequest: .atLeast(1))
		)
	}
}
