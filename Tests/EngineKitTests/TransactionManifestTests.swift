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

	func test_eq_larger() throws {
		func manifest(account: String) throws -> TransactionManifest {
			let string = """
			CALL_METHOD
			    Address("\(account)")
			    "withdraw"
			    Address("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    Decimal("0")
			;
			CALL_METHOD
			    Address("\(account)")
			    "withdraw"
			    Address("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
			    Decimal("0")
			;
			TAKE_ALL_FROM_WORKTOP
			    Address("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    Bucket("bucket1")
			;
			TAKE_ALL_FROM_WORKTOP
			    Address("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
			    Bucket("bucket2")
			;
			ALLOCATE_GLOBAL_ADDRESS
			    Address("package_rdx1pktjwpsjw3le09znnaxjxfzfy47sq8gt7r3p5v2wrn7ertcdtgs537")
			    "QuantaSwap"
			    AddressReservation("reservation1")
			    NamedAddress("address1")
			;
			CALL_METHOD
			    Address("component_rdx1czw7wqlfyum0ythajk5f2nnc6egq5y2wla39v5rfwxg9xvxe50vl5q")
			    "new_pool"
			    Address("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    Address("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
			    5u32
			    Enum<1u8>(
			        AddressReservation("reservation1")
			    )
			;
			CALL_METHOD
			    NamedAddress("address1")
			    "add_liquidity"
			    Bucket("bucket1")
			    Bucket("bucket2")
			    Array<Tuple>(
			        Tuple(
			            25955u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25970u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25965u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25960u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25950u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25945u32,
			            Decimal("0"),
			            Decimal("0")
			        ),
			        Tuple(
			            25940u32,
			            Decimal("0"),
			            Decimal("0")
			        )
			    )
			;
			CALL_METHOD
			    Address("\(account)")
			    "try_deposit_batch_or_abort"
			    Expression("ENTIRE_WORKTOP")
			    Enum<0u8>()
			;
			"""
			return try TransactionManifest(instructions: .fromString(string: string, networkId: NetworkID.mainnet.rawValue), blobs: [])
		}
		let accountA = "account_rdx1283u6e8r2jnz4a3jwv0hnrqfr5aq50yc9ts523sd96hzfjxqqcs89q"
		let accountB = "account_rdx12x533g087dk8xtdrqh7m4tcpy4mrakyzqppydlzpvdh8axksxhy7fc"

		try XCTAssertEqual(manifest(account: accountA), manifest(account: accountA))
		try XCTAssertEqual(manifest(account: accountB), manifest(account: accountB))
		try XCTAssertNotEqual(manifest(account: accountA), manifest(account: accountB))
		try XCTAssertNotEqual(manifest(account: accountB), manifest(account: accountA))
	}
}
