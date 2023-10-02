import EngineKit
import EngineToolkit
import TestingPrelude

final class TransactionManifestTests: TestCase {
	func test_eq() throws {
		func manifest(recipient: String) throws -> TransactionManifest {
			let string = """
			ALLOCATE_GLOBAL_ADDRESS
			    Address("package_tdx_2_1pkgxxxxxxxxxresrcexxxxxxxxx000538436477xxxxxxxxxmn4mes")
			    "FungibleResourceManager"
			    AddressReservation("owner_address_reservation")
			    NamedAddress("owner_address")
			;
			CREATE_FUNGIBLE_RESOURCE_WITH_INITIAL_SUPPLY
			    Enum<0u8>()
			    true
			    1u8
			    Decimal("1")
			    Tuple(
			        Enum<0u8>(),
			        Enum<0u8>(),
			        Enum<0u8>(),
			        Enum<0u8>(),
			        Enum<0u8>(),
			        Enum<0u8>()
			    )
			    Tuple(
			        Map<String, Tuple>(),
			        Map<String, Enum>()
			    )
			    Enum<1u8>(
			        AddressReservation("owner_address_reservation")
			    )
			;
			CALL_METHOD
			    Address("\(recipient)")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP")
			;
			"""
			return try TransactionManifest(instructions: .fromString(string: string, networkId: NetworkID.stokenet.rawValue), blobs: [])
		}
		let accountA = "account_tdx_2_12ygsf87pma439ezvdyervjfq2nhqme6reau6kcxf6jtaysaxl7sqvd"
		let accountB = "account_tdx_2_12yymsmxapnaulngrepgdyzlaszflhcynchr2s95nkjfrsfuzq02s8m"
		try XCTAssertEqual(manifest(recipient: accountA), manifest(recipient: accountA))
		try XCTAssertEqual(manifest(recipient: accountB), manifest(recipient: accountB))
		try XCTAssertNotEqual(manifest(recipient: accountA), manifest(recipient: accountB))
		try XCTAssertNotEqual(manifest(recipient: accountB), manifest(recipient: accountA))
	}
}
