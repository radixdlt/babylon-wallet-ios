import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class RadixConnectModelsTest: TestCase {
	func test_p2p_client_eq() throws {
		let publicKey = try Curve25519PublicKeyBytes(.init(.deadbeef32Bytes))
		let firstPW = try ConnectionPassword(.init(.deadbeef32Bytes))
		let secondPW = try ConnectionPassword(.init(.deadbeef32Bytes))
		let first = P2PLink(connectionPassword: firstPW, publicKey: publicKey, purpose: .general, displayName: "first")
		let second = P2PLink(connectionPassword: secondPW, publicKey: publicKey, purpose: .general, displayName: "second")
		XCTAssertEqual(first, second)
		var clients = P2PLinks(.init())
		XCTAssertEqual(clients.append(first), first)
		XCTAssertNil(clients.append(second))
	}
}
