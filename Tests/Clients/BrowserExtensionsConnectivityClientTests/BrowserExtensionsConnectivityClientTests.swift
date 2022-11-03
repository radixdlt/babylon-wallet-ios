@testable import BrowserExtensionsConnectivityClient
import Foundation
import TestUtils

final class BrowerExtensionsConnectivityClientTests: TestCase {
	func test_decode_request_from_dApp() throws {
		let jsonOLD = """
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

		"""
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
		  "requestId" : "70bd4ad5-66aa-47cb-9698-afcdafbe3964"
		}
		"""

		let decoder = JSONDecoder()
		let request = try decoder.decode(RequestMethodWalletRequest.self, from: json)
		XCTAssertEqual(request.payload, [RequestMethodWalletRequest.Payload.accountAddresses(.init(requestType: .accountAddresses, numberOfAddresses: 1))])
	}
}
