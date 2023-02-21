import ClientTestingPrelude
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
	private func interaction(
		origin: String,
		dAppDefinitionAddress: String
	) -> P2P.FromDapp.WalletInteraction {
		.init(
			id: "",
			items: .request(.authorized(.init(
				auth: .login(.init(challenge: nil)),
				oneTimeAccounts: nil,
				ongoingAccounts: nil
			))),
			metadata: .init(
				networkId: 0,
				origin: .init(rawValue: origin),
				dAppDefinitionAddress: try! .init(address: dAppDefinitionAddress)
			)
		)
	}

	private func json(dAppDefinitionAddress: String) -> JSON {
		[
			"dApps": [
				[
					"dAppDefinitionAddress": .string(dAppDefinitionAddress),
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

	func testHappyPath() async throws {
		// given
		let origin = "https://origin.com"
		let dAppDefinitionAddress = "dAppDefinitionAddress-deadbeef"
		let interaction = interaction(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
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
			try await sut.performWellKnownFileCheck(interaction)
		}
	}

	func testUnhappyPath_whenOriginURLIsInvalid_thenInvalidOriginURLErrorIsThrown() async throws {
		// given
		let origin = ""
		let dAppDefinitionAddress = "dAppDefinitionAddress-deadbeef"
		let interaction = interaction(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
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
		var didFailWithError: Error?

		// when
		await withDependencies {
			$0.urlSession = urlSession
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(interaction)
			} catch {
				didFailWithError = error
				XCTAssertEqual(error as! ROLAFailure, expectedError)
			}
		}

		XCTAssertNotNil(didFailWithError)
	}

	func testUnhappyPath_whenJsonFileFormatIsInvalid_thenUknownFileFormatErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let dAppDefinitionAddress = "dAppDefinitionAddress-deadbeef"
		let interaction = interaction(origin: origin, dAppDefinitionAddress: dAppDefinitionAddress)
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

		let expectedError = ROLAFailure.uknownFileFormat
		var didFailWithError: Error?

		// when
		await withDependencies {
			$0.urlSession = urlSession
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(interaction)
			} catch {
				didFailWithError = error
				XCTAssertEqual(error as! ROLAFailure, expectedError)
			}
		}

		XCTAssertNotNil(didFailWithError)
	}

	func testUnhappyPath_whenDappDefinitionAddressIsUnknown_thenUnknownDappDefinitionAddressErrorIsThrown() async throws {
		// given
		let origin = "https://origin.com"
		let knownDappDefinitionAddress = "dAppDefinitionAddress-deadbeef"
		let unknownDappDefinitionAddress = "unknown-deadbeef"
		let interaction = interaction(origin: origin, dAppDefinitionAddress: unknownDappDefinitionAddress)
		let json = json(dAppDefinitionAddress: knownDappDefinitionAddress)
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
		var didFailWithError: Error?

		// when
		await withDependencies {
			$0.urlSession = urlSession
		} operation: {
			do {
				try await sut.performWellKnownFileCheck(interaction)
			} catch {
				didFailWithError = error
				XCTAssertEqual(error as! ROLAFailure, expectedError)
			}
		}

		XCTAssertNotNil(didFailWithError)
	}
}

// MARK: - MockURLProtocol
class MockURLProtocol: URLProtocol {
	static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
	override class func canInit(with request: URLRequest) -> Bool { true }
	override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

	override func startLoading() {
		guard let handler = MockURLProtocol.requestHandler else {
			fatalError("Handler unimplemented")
		}

		do {
			let (response, data) = try handler(request)
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			if let data = data {
				client?.urlProtocol(self, didLoad: data)
			}
			client?.urlProtocolDidFinishLoading(self)
		} catch {
			client?.urlProtocol(self, didFailWithError: error)
		}
	}

	override func stopLoading() {}
}
