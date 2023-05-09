import CacheClient
import ClientTestingPrelude
import EngineToolkit
import GatewayAPI
@testable import ROLAClient

// MARK: - ROLAClientTests
final class ROLAClientTests: TestCase {
	private var sut: ROLAClient!
	private var urlSession: URLSession = {
		let configuration: URLSessionConfiguration = .default
		configuration.protocolClasses = [MockURLProtocol.self]
		return .init(configuration: configuration)
	}()

	private let wellKnownFilePath = ".well-known/radix.json"
	private let dAppDefinitionAddress = try! DappDefinitionAddress(address: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh")
	private func metadata(
		origin: String,
		dAppDefinitionAddress: DappDefinitionAddress
	) -> P2P.Dapp.Request.Metadata {
		.init(
			networkId: 0,
			origin: .init(rawValue: origin),
			dAppDefinitionAddress: dAppDefinitionAddress
		)
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
		try testFixture(bundle: .module, jsonName: "rola_challenge_payload_hash_vectors") { (vectors: [TestVector]) in
			for vector in vectors {
				let payload = try payloadToHash(
					challenge: .init(rawValue: .init(hex: vector.challenge)),
					dAppDefinitionAddress: .init(address: vector.dAppDefinitionAddress),
					origin: .init(rawValue: vector.origin)
				)
				XCTAssertEqual(payload.hex, vector.payloadToHash)
				let blakeHashOfPayload = try blake2b(data: payload)
				XCTAssertEqual(blakeHashOfPayload.hex, vector.blakeHashOfPayload)
			}
		}
	}

	func omit_test_generate_rola_payload_hash_vectors() throws {
		let origins: [P2P.Dapp.Request.Metadata.Origin] = ["https://dashboard.rdx.works", "https://stella.swap", "https://rola.xrd"]
		let accounts: [DappDefinitionAddress] = try [
			.init(address: "account_tdx_b_1p9dkged3rpzy860ampt5jpmvv3yl4y6f5yppp4tnscdslvt9v3"),
			.init(address: "account_tdx_b_1p95nal0nmrqyl5r4phcspg8ahwnamaduzdd3kaklw3vqeavrwa"),
			.init(address: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"),
		]
		let vectors: [TestVector] = try origins.flatMap { origin -> [TestVector] in
			try accounts.flatMap { dAppDefinitionAddress -> [TestVector] in
				try (UInt8.zero ..< 10).map { seed -> TestVector in
					/// deterministic derivation of a challenge, this is not `blakeHashOfPayload`
					let challenge = try blake2b(data: Data((origin.rawValue + dAppDefinitionAddress.address).utf8) + [seed])
					let payload = try payloadToHash(
						challenge: .init(rawValue: .init(data: challenge)),
						dAppDefinitionAddress: dAppDefinitionAddress,
						origin: origin
					)
					let blakeHashOfPayload = try blake2b(data: payload)
					return TestVector(
						origin: origin.rawValue,
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
			try await sut.performWellKnownFileCheck(metadata)
		}
	}

	func testHappyPath_performDappDefinitionVerification() async throws {
		// given
		let origin = "https://origin.com"
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
		let accountType = "dapp definition"
		let metadataCollection = GatewayAPI.EntityMetadataCollection(items: [
			.init(key: "account_type", value: .init(rawHex: "", rawJson: "", asString: accountType), lastUpdatedAtStateVersion: 0),
			.init(key: "related_websites", value: .init(rawHex: "", rawJson: "", asString: origin), lastUpdatedAtStateVersion: 0),
		])

		// when
		try await withDependencies {
			$0.gatewayAPIClient.getEntityMetadata = { _ in metadataCollection }
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

		let metadataCollection = GatewayAPI.EntityMetadataCollection(items: [
			.init(key: "account_type", value: .init(rawHex: "", rawJson: "", asString: wrongAccountType), lastUpdatedAtStateVersion: 0),
			.init(key: "related_websites", value: .init(rawHex: "", rawJson: "", asString: origin), lastUpdatedAtStateVersion: 0),
		])

		let expectedError = ROLAFailure.wrongAccountType

		// when
		await withDependencies {
			$0.gatewayAPIClient.getEntityMetadata = { _ in metadataCollection }
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performDappDefinitionVerification(metadata)
				XCTFail("Expected error: wrongAccountType")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}

	func testUnhappyPath_whenOriginIsUnknown_thenUnknownWebsiteErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let originFromDapp = "https://someotherorigin.com"
		let metadata = metadata(origin: originFromDapp, dAppDefinitionAddress: dAppDefinitionAddress)
		let accountType = "dapp definition"

		let metadataCollection = GatewayAPI.EntityMetadataCollection(items: [
			.init(key: "account_type", value: .init(rawHex: "", rawJson: "", asString: accountType), lastUpdatedAtStateVersion: 0),
			.init(key: "related_websites", value: .init(rawHex: "", rawJson: "", asString: origin), lastUpdatedAtStateVersion: 0),
		])

		let expectedError = ROLAFailure.unknownWebsite

		// when
		await withDependencies {
			$0.gatewayAPIClient.getEntityMetadata = { _ in metadataCollection }
			$0.cacheClient.load = { _, _ in throw CacheClient.Error.dataLoadingFailed }
			$0.cacheClient.save = { _, _ in }
		} operation: {
			do {
				try await sut.performDappDefinitionVerification(metadata)
				XCTFail("Expected error: unknownWebsite")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}

	func testUnhappyPath_whenOriginURLIsInvalid_thenInvalidOriginURLErrorIsThrown() async throws {
		// given
		let origin = ""
		let metadata = metadata(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
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

		let expectedError = ROLAFailure.invalidOriginURL

		// when
		await withDependencies {
			$0.urlSession = urlSession
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(metadata)
				XCTFail("Expected error: invalidOriginURL")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
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
				try await sut.performWellKnownFileCheck(metadata)
				XCTFail("Expected error: radixJsonUnknownFileFormat")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}

	func testUnhappyPath_whenDappDefinitionAddressIsUnknown_thenUnknownDappDefinitionAddressErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let unknownDappDefinitionAddress = try! DappDefinitionAddress(address: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh-unknown") // TODO: use another valid DappDefinitionAddress
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
				try await sut.performWellKnownFileCheck(metadata)
				XCTFail("Expected error: unknownDappDefinitionAddress")
			} catch {
				XCTAssertEqual(error as? ROLAFailure, expectedError)
			}
		}
	}
}
