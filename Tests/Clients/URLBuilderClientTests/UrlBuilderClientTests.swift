import Foundation
import TestUtils
@testable import URLBuilderClient

final class URLBuilderClientTests: TestCase {
	let sut = URLBuilderClient.liveValue
	func test_dns_with_port() throws {
		let url = try XCTUnwrap(URL(string: "https://example.with.ports.com:12345"))
		XCTAssertEqual(url.port, 12345)
	}

	func test_ip_no_scheme_with_port_using_builder() throws {
		let url = try XCTUnwrap(URL(string: "12.34.56.78:12345"))
		XCTAssertNil(url.port, "URL is broken using IP addresses...")
		let url2 = try sut.urlFromInput(.init(host: "12.34.56.78", port: 12345))
		XCTAssertEqual(url2.port, 12345)
	}

	func test_all() throws {
		let url = try sut.urlFromInput(.init(
			host: "alphanet.radixdlt.com",
			scheme: "https",
			path: "/v0",
			port: 12345
		))
		XCTAssertEqual(url.port, 12345)
	}
}
