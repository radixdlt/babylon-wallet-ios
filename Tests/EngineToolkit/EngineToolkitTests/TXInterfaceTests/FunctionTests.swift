@testable import EngineToolkit
import TestingPrelude

final class FunctionCallsTest: TestCase {
	let decoder = JSONDecoder()

	func test_extractAddressesFromManifest() throws {
		try test_function(sut.staticallyValidateTransaction)
		try test_function(sut.extractAddressesFromManifest)
		// TODO: Add analyzeTransactionExecution

		try test_function(sut.decodeAddressRequest(request:))
		try test_function(sut.encodeAddressRequest(request:))

		try test_function(sut.compileNotarizedTransactionIntentRequest(request:))
		try test_function(sut.decompileNotarizedTransactionIntentRequest(request:))

		try test_function(sut.compileSignedTransactionIntentRequest(request:))
		try test_function(sut.decompileSignedTransactionIntentRequest(request:))

		try test_function(sut.compileTransactionIntentRequest(request:))
		try test_function(sut.decompileTransactionIntentRequest(request:))

		try test_function(sut.decompileUnknownTransactionIntentRequest(request:))

		try test_function(sut.deriveVirtualAccountAddressRequest(request:))
		try test_function(sut.deriveVirtualIdentityAddressRequest(request:))
		try test_function(sut.deriveOlympiaAddressFromPublicKeyRequest(request:))
		try test_function(sut.hashRequest(request:))
//		// try test_function(sut.knownEntityAddresses(request:))
	}

	private func test_function<Request: Decodable, Response: Decodable & Equatable>(_ f: (Request) -> Result<Response, RadixEngine.Error>) throws {
		let request = try decoder.decode(
			Request.self,
			from: resource(named: String(describing: Request.self), extension: "json")
		)

		let expectedResponse = try decoder.decode(
			Response.self,
			from: resource(named: String(describing: Response.self), extension: "json")
		)

		let decodedResponse = try f(request).get()
		XCTAssertEqual(expectedResponse, decodedResponse)
	}
}
