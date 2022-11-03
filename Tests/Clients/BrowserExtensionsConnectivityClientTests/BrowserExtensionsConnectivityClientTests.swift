@testable import BrowserExtensionsConnectivityClient
import Foundation
import TestUtils

final class BrowerExtensionsConnectivityClientTests: TestCase {
	func test_decode_request_from_dApp() throws {
		let json = """
		{
		  "metadata" : {
		    "networkId" : 1,
		    "dAppId" : "radixDashboard"
		  },
		  "payload" : [
		    {
		      "requestType" : "accountAddresses",
		      "numberOfAddresses" : 1
		    }
		  ],
		  "method" : "request",
		  "requestId" : "950c5126-0fff-4b83-a1c7-0fd6e4c88812"
		}
		""".data(using: .utf8)!

		let decoder = JSONDecoder()
		let request = try decoder.decode(RequestMethodWalletRequest.self, from: json)
		XCTAssertEqual(request.payloads, [RequestMethodWalletRequest.Payload.accountAddresses(.init(requestType: .accountAddresses, numberOfAddresses: 1))])
	}

	func test_decode_sign_tx_request() throws {
		let json = """
		{
		  "metadata" : {
		    "networkId" : 1,
		    "dAppId" : "radixDashboard"
		  },
		  "payload" : [
		    {
		      "accountAddress" : "account_sim1q02r73u7nv47h80e30pc3q6ylsj7mgvparm3pnsm780qgsy064",
		      "version" : 1,
		      "transactionManifest" : "",
		      "requestType" : "sendTransaction"
		    }
		  ],
		  "method" : "sendTransaction",
		  "requestId" : "ed987de8-fc30-40d0-81ea-e3eef117a2cc"
		}
		""".data(using: .utf8)!
		let decoder = JSONDecoder()
		let request = try decoder.decode(RequestMethodWalletRequest.self, from: json)
		XCTAssertEqual(request.method, .sendTransaction)
		XCTAssertEqual(request.payloads[0].requestType, .sendTransaction)
	}
}
