import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class IdentifiedArrayOfTests: XCTestCase {
	// https://github.com/pointfreeco/swift-identified-collections/pull/66
	func testIdentifiedArraySubscript() {
		struct ProtoAccount: Identifiable {
			let id: AccountAddress
		}
		var items: IdentifiedArrayOf<ProtoAccount> = [ProtoAccount(id: .sample), ProtoAccount(id: .sampleOther)]
		items[1] = ProtoAccount(id: .sampleStokenet)
		XCTAssertEqual(2, items.count)
		XCTAssertEqual([AccountAddress.sample, .sampleStokenet], items.map(\.id))
	}
}
