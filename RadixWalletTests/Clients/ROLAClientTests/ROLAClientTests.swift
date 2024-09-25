import JSONTesting
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - ROLAClientTests
final class ROLAClientTests: TestCase {
	private var sut: ROLAClient!
	private var urlSession: URLSession = {
		let configuration: URLSessionConfiguration = .default
		configuration.protocolClasses = [MockURLProtocol.self]
		return .init(configuration: configuration)
	}()

	private let wellKnownFilePath = ".well-known/radix.json"
	private let dAppDefinitionAddress = try! DappDefinitionAddress(validatingAddress: "account_rdx12xsvygvltz4uhsht6tdrfxktzpmnl77r0d40j8agmujgdj022sudkk")
	private func metadata(
		origin: String,
		dAppDefinitionAddress: DappDefinitionAddress
	) -> DappToWalletInteractionMetadata {
		.init(
			version: 1,
			networkId: NetworkID.mainnet,
			origin: origin,
			dappDefinitionAddress: dAppDefinitionAddress
		)
	}

	private func entityMetadata(
		origin: String,
		accountType: String
	) -> GatewayAPI.EntityMetadataCollection {
		.init(items: [
			.init(key: "account_type", value: .init(rawHex: "", programmaticJson: .i8(.init(kind: .i8, value: "1")), typed: .stringValue(.init(type: .string, value: accountType))), isLocked: false, lastUpdatedAtStateVersion: 0),
			.init(key: "claimed_websites", value: .init(rawHex: "", programmaticJson: .i8(.init(kind: .i8, value: "1")), typed: .originArrayValue(.init(type: .originArray, values: [origin]))), isLocked: false, lastUpdatedAtStateVersion: 0),
		])
	}

	private func json(dAppDefinitionAddress: DappDefinitionAddress) -> JSON {
		[
			"dApps": [
				[
					"dAppDefinitionAddress": .string(dAppDefinitionAddress.address),
				],
			],
		]
	}

	override func setUp() async throws {
		try await super.setUp()
		sut = ROLAClient.liveValue
	}

	override func tearDown() async throws {
		sut = nil
		try await super.tearDown()
	}

	struct TestVector: Sendable, Hashable, Codable {
		let origin: String
		let challenge: String
		let dAppDefinitionAddress: String
		let payloadToHash: String
		let blakeHashOfPayload: String
	}

	func test_rola_payload_hash_vectors() throws {
		try testFixture(
			bundle: Bundle(for: Self.self),
			jsonName: "rola_challenge_payload_hash_vectors"
		) { (vectors: [TestVector]) in
			for vector in vectors {
				let payload = try ROLAClient.payloadToHash(
					challenge: .init(hex: vector.challenge),
					dAppDefinitionAddress: .init(validatingAddress: vector.dAppDefinitionAddress),
					origin: vector.origin
				)
				XCTAssertEqual(payload.hex, vector.payloadToHash)
				let blakeHashOfPayload = payload.hash()
				XCTAssertEqual(blakeHashOfPayload.hex, vector.blakeHashOfPayload)
			}
		}
	}

	func omit_test_generate_rola_payload_hash_vectors() throws {
		let origins: [DappOrigin] = [
			"https://dashboard.rdx.works",
			"https://stella.swap",
			"https://rola.xrd",
		]
		let accounts: [DappDefinitionAddress] = try [
			"account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q",
			"account_sim1cyzfj6p254jy6lhr237s7pcp8qqz6c8ahq9mn6nkdjxxxat5syrgz9",
			"account_sim168gge5mvjmkc7q4suyt3yddgk0c7yd5z6g662z4yc548cumw8nztch",
		].map { try .init(validatingAddress: $0) }
		let vectors: [TestVector] = try origins.flatMap { origin -> [TestVector] in
			try accounts.flatMap { dAppDefinitionAddress -> [TestVector] in
				try (UInt8.zero ..< 10).map { seed -> TestVector in
					/// deterministic derivation of a challenge, this is not `blakeHashOfPayload`
					let challenge = (Data((origin + dAppDefinitionAddress.address).utf8) + [seed]).hash()
					let payload = ROLAClient.payloadToHash(
						challenge: challenge.bytes,
						dAppDefinitionAddress: dAppDefinitionAddress,
						origin: origin
					)
					let blakeHashOfPayload = payload.hash()
					return TestVector(
						origin: origin,
						challenge: challenge.hex,
						dAppDefinitionAddress: dAppDefinitionAddress.address,
						payloadToHash: payload.hex,
						blakeHashOfPayload: blakeHashOfPayload.hex
					)
				}
			}
		}
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
		let json = try jsonEncoder.encode(vectors)
		print(String(data: json, encoding: .utf8)!)
	}

	func test_sign_auth() throws {
		let mnemonic = try Mnemonic(phrase: "equip will roof matter pink blind book anxiety banner elbow sun young", language: .english)
		let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: "")
		let accountPath = try AccountPath(string: "m/44H/1022H/12H/525H/1460H/1H")
		let publicKey = mnemonicWithPassphrase.derivePublicKey(path: accountPath)
		XCTAssertEqual(publicKey.publicKey.hex, "0a4b894208a1f6b1bd7e823b59909f01aae0172b534baa2905b25f1bcbbb4f0a")
		let hash: Hash = try {
			let payload = try ROLAClient.payloadToHash(
				challenge: Exactly32Bytes(hex: "2596b7902d56a32d17ca90ce2a1ee0a18a9cac6a82fb9f186d904e4a3eeeb627"),
				dAppDefinitionAddress: .init(validatingAddress: "account_rdx168fghy4kapzfnwpmq7t7753425lwklk65r82ys7pz2xzleehk2ap0k"),
				origin: "https://radix-dapp-toolkit-dev.rdx-works-main.extratools.works"
			)
			return payload.hash()
		}()
		let signature = mnemonicWithPassphrase.sign(hash: hash, path: accountPath)
		XCTAssertTrue(signature.isValid(hash))
	}

	func testHappyPath_performWellKnownFileCheck() async throws {
		// given
		let origin = "https://origin.com"
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
		let json = json(dAppDefinitionAddress: dAppDefinitionAddress)
		let expectedURL = URL(string: "https://origin.com/.well-known/radix.json")!

		MockURLProtocol.requestHandler = { request in
			guard let url = request.url, url == expectedURL else {
				XCTFail("Expected url: \(expectedURL)")
				fatalError()
			}

			let response = HTTPURLResponse(
				url: expectedURL,
				statusCode: 200,
				httpVersion: nil,
				headerFields: nil
			)!

			return (response, json.data)
		}

		// when
		try await withDependencies {
			$0.urlSession = urlSession
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			try await sut.performWellKnownFileCheck(metadata.origin.url(), metadata.dappDefinitionAddress)
		}
	}

	func testHappyPath_performDappDefinitionVerification() async throws {
		// given
		let origin = "https://origin.com"
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
		let accountType = "dapp definition"
		let metadataCollection = entityMetadata(origin: origin, accountType: accountType)

		// when
		try await withDependencies {
			$0.onLedgerEntitiesClient.getEntities = { _, _, _, _, _ in
				[.account(.withMetadata(.init(metadataCollection)))]
			}
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			try await sut.performDappDefinitionVerification(metadata)
		}
	}

	func testUnhappyPath_whenAccountTypeIsWrong_thenWrongAccountTypeErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
		let wrongAccountType = "wrong account type"
		let metadataCollection = entityMetadata(origin: origin, accountType: wrongAccountType)

		let expectedError = OnLedgerEntity.Metadata.MetadataError.accountTypeNotDappDefinition

		// when
		await withDependencies {
			$0.onLedgerEntitiesClient.getEntities = { _, _, _, _, _ in
				[.account(.withMetadata(.init(metadataCollection)))]
			}
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performDappDefinitionVerification(metadata)
				XCTFail("Expected error: wrongAccountType")
			} catch {
				XCTAssertEqual(error as? OnLedgerEntity.Metadata.MetadataError, expectedError)
			}
		}
	}

	func testUnhappyPath_whenOriginIsUnknown_thenUnknownWebsiteErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let originFromDapp = "https://someotherorigin.com"
		let metadata = metadata(origin: originFromDapp, dAppDefinitionAddress: dAppDefinitionAddress)
		let accountType = "dapp definition"
		let metadataCollection = entityMetadata(origin: origin, accountType: accountType)

		let expectedError = OnLedgerEntity.Metadata.MetadataError.websiteNotClaimed

		// when
		await withDependencies {
			$0.onLedgerEntitiesClient.getEntities = { _, _, _, _, _ in
				[.account(.withMetadata(.init(metadataCollection)))]
			}
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performDappDefinitionVerification(metadata)
				XCTFail("Expected error: unknownWebsite")
			} catch {
				print("• error", error)
				XCTAssertEqual(error as? OnLedgerEntity.Metadata.MetadataError, expectedError)
			}
		}
	}

	func testUnhappyPath_whenJsonFileFormatIsInvalid_thenUknownFileFormatErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
		let json: JSON = []
		let expectedURL = URL(string: "/.well-known/radix.json")!

		MockURLProtocol.requestHandler = { _ in
			let response = HTTPURLResponse(
				url: expectedURL,
				statusCode: 200,
				httpVersion: nil,
				headerFields: nil
			)!
			return (response, json.data)
		}

		let expectedError = ROLAFailure.radixJsonUnknownFileFormat

		// when
		await withDependencies {
			$0.urlSession = urlSession
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(metadata.origin.url(), metadata.dappDefinitionAddress)
				XCTFail("Expected error: radixJsonUnknownFileFormat")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}

	func testUnhappyPath_whenDappDefinitionAddressIsUnknown_thenUnknownDappDefinitionAddressErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let unknownDappDefinitionAddress = try! DappDefinitionAddress(validatingAddress: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q") // TODO: use another valid DappDefinitionAddress
		let metadata = metadata(origin: origin, dAppDefinitionAddress: unknownDappDefinitionAddress)
		let json = json(dAppDefinitionAddress: dAppDefinitionAddress)
		let expectedURL = URL(string: "/.well-known/radix.json")!

		MockURLProtocol.requestHandler = { _ in
			let response = HTTPURLResponse(
				url: expectedURL,
				statusCode: 200,
				httpVersion: nil,
				headerFields: nil
			)!
			return (response, json.data)
		}

		let expectedError = ROLAFailure.unknownDappDefinitionAddress

		// when
		await withDependencies {
			$0.urlSession = urlSession
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(metadata.origin.url(), metadata.dappDefinitionAddress)
				XCTFail("Expected error: unknownDappDefinitionAddress")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}
}

extension OnLedgerEntity.OnLedgerAccount {
	static func withMetadata(_ metadata: OnLedgerEntity.Metadata) -> Self {
		.init(address: .wallet,
		      atLedgerState: .init(version: 0, epoch: 0),
		      metadata: metadata,
		      fungibleResources: .init(),
		      nonFungibleResources: [],
		      poolUnitResources: .init(radixNetworkStakes: [], poolUnits: []))
	}
}
