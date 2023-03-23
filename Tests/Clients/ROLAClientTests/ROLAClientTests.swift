import ClientTestingPrelude
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
	let ledgerState = GatewayAPI.LedgerState(
		network: "network-deadbeef",
		stateVersion: 0,
		proposerRoundTimestamp: "timestamp-deadbeef",
		epoch: 0,
		round: 0
	)
	private func metadata(
		origin: String,
		dAppDefinitionAddress: DappDefinitionAddress
	) -> P2P.FromDapp.WalletInteraction.Metadata {
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
			$0.gatewayAPIClient.getEntityDetails = { _ in
				GatewayAPI.StateEntityDetailsResponse(
					ledgerState: self.ledgerState,
					items: [
						.init(address: "address-deadbeef", metadata: metadataCollection),
					]
				)
			}
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
			$0.gatewayAPIClient.getEntityDetails = { _ in
				GatewayAPI.StateEntityDetailsResponse(
					ledgerState: self.ledgerState,
					items: [
						.init(address: "address-deadbeef", metadata: metadataCollection),
					]
				)
			}
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
			$0.gatewayAPIClient.getEntityDetails = { _ in
				GatewayAPI.StateEntityDetailsResponse(
					ledgerState: self.ledgerState,
					items: [
						.init(address: "address-deadbeef", metadata: metadataCollection),
					]
				)
			}
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
