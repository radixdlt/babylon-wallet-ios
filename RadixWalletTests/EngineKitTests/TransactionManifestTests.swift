import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class TransactionManifestTests: TestCase {
	func test_equatable_and_hashable_small() throws {
		func manifest(recipient: String) throws -> TransactionManifest {
			let string = """
			ALLOCATE_GLOBAL_ADDRESS
			    EngineToolkitAddress("package_tdx_2_1pkgxxxxxxxxxresrcexxxxxxxxx000538436477xxxxxxxxxmn4mes")
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
			    EngineToolkitAddress("\(recipient)")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP")
			;
			"""
			return try TransactionManifest(instructions: .fromString(string: string, networkId: NetworkID.stokenet.rawValue), blobs: [])
		}

		let manifestA = try manifest(
			recipient: "account_tdx_2_12ygsf87pma439ezvdyervjfq2nhqme6reau6kcxf6jtaysaxl7sqvd"
		)
		let manifestB = try manifest(
			recipient: "account_tdx_2_12yymsmxapnaulngrepgdyzlaszflhcynchr2s95nkjfrsfuzq02s8m"
		)

		XCTAssertEqual(manifestA, manifestA)
		XCTAssertEqual(manifestB, manifestB)
		XCTAssertNotEqual(manifestB, manifestA)

		// Hashable testing
		XCTAssertEqual(Set([manifestA, manifestB]).count, 2)
		XCTAssertEqual(Set([manifestA, manifestA]).count, 1)
		XCTAssertEqual(Set([manifestB, manifestB]).count, 1)
	}

	func test_equatable_and_hashable_larger() throws {
		func manifest(account: String) throws -> TransactionManifest {
			let string = """
			CALL_METHOD
			    EngineToolkitAddress("\(account)")
			    "withdraw"
			    EngineToolkitAddress("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    Decimal("0")
			;
			CALL_METHOD
			    EngineToolkitAddress("\(account)")
			    "withdraw"
			    EngineToolkitAddress("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
			    Decimal("0")
			;
			TAKE_ALL_FROM_WORKTOP
			    EngineToolkitAddress("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    Bucket("bucket1")
			;
			TAKE_ALL_FROM_WORKTOP
			    EngineToolkitAddress("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
			    Bucket("bucket2")
			;
			ALLOCATE_GLOBAL_ADDRESS
			    EngineToolkitAddress("package_rdx1pktjwpsjw3le09znnaxjxfzfy47sq8gt7r3p5v2wrn7ertcdtgs537")
			    "QuantaSwap"
			    AddressReservation("reservation1")
			    NamedAddress("address1")
			;
			CALL_METHOD
			    EngineToolkitAddress("component_rdx1czw7wqlfyum0ythajk5f2nnc6egq5y2wla39v5rfwxg9xvxe50vl5q")
			    "new_pool"
			    EngineToolkitAddress("resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")
			    EngineToolkitAddress("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
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
			    EngineToolkitAddress("\(account)")
			    "try_deposit_batch_or_abort"
			    Expression("ENTIRE_WORKTOP")
			    Enum<0u8>()
			;
			"""
			return try TransactionManifest(instructions: .fromString(string: string, networkId: NetworkID.mainnet.rawValue), blobs: [])
		}

		let manifestA = try manifest(
			account: "account_rdx1283u6e8r2jnz4a3jwv0hnrqfr5aq50yc9ts523sd96hzfjxqqcs89q"
		)
		let manifestB = try manifest(
			account: "account_rdx12x533g087dk8xtdrqh7m4tcpy4mrakyzqppydlzpvdh8axksxhy7fc"
		)

		XCTAssertEqual(manifestA, manifestA)
		XCTAssertEqual(manifestB, manifestB)
		XCTAssertNotEqual(manifestB, manifestA)

		// Hashable testing
		XCTAssertEqual(Set([manifestA, manifestB]).count, 2)
		XCTAssertEqual(Set([manifestA, manifestA]).count, 1)
		XCTAssertEqual(Set([manifestB, manifestB]).count, 1)
	}
}
