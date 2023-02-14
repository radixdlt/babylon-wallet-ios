import EngineToolkit
import TestingPrelude

// MARK: - EncodeDecodeAddressRequestTests
final class EncodeDecodeAddressRequestTests: TestCase {
	override func setUp() {
		debugPrint = false
		super.setUp()
		continueAfterFailure = false
	}

	func test__encodeDecodeAddressRequest() throws {
		try TestSuite.vectors.forEach { try doTest(vector: $0) }
	}
}

extension EncodeDecodeAddressRequestTests {
	private func doTest(
		vector: AddressDecodeEncodeTestVectors.Vector,
		networkID: NetworkID = .simulator,
		line: UInt = #line
	) throws {
		let decodeRequest = DecodeAddressRequest(
			address: vector.encoded
		)
		XCTAssertNoThrow(try sut.decodeAddressRequest(request: decodeRequest).get())

		let encodeRequest = try EncodeAddressRequest(
			addressHex: vector.decoded,
			networkId: networkID
		)
		let encoded = try sut.encodeAddressRequest(request: encodeRequest).get()
		XCTAssertNoDifference(encoded.address, vector.encoded)
	}

	fileprivate typealias TestSuite = AddressDecodeEncodeTestVectors
}

// MARK: - AddressDecodeEncodeTestVectors
enum AddressDecodeEncodeTestVectors {
	private static let encoded: [String] = [
		"package_sim1q88ghe0tnzqqc90xjskj0cmntxwp3gv7pzjnx7p5r54qjm0utr",
		"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsnznk7n",
		"package_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpsuluv44",
		"package_sim1qy7rfwzgm99jp4lwngv8utfnzxd7zv2fq9p279rzzmws555ujt",
		"package_sim1q8jy0frw4en9cdc63cyj2n7pdefj95lftvrdamjhhyqqlgshez",
		"account_sim1qv0z2nsg5aqayjeszxa9uc6p82nalts0cm2sdna69g7sm3626z",
		"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqshxgp7h",
		"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqd60rqz",
		"resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag",
		"resource_sim1qqe4m2jlrz5y82syz3y76yf9ztd4trj7fmlq4vf4gmzsf6wgzy",
	]

	private static let decoded: [String] = [
		"01ce8be5eb98800c15e6942d27e373599c18a19e08a53378341d2a",
		"010000000000000000000000000000000000000000000000000001",
		"010000000000000000000000000000000000000000000000000003",
		"013c34b848d94b20d7ee9a187e2d33119be131490142af146216dd",
		"01e447a46eae665c371a8e09254fc16e5322d3e95b06deee57b900",
		"031e254e08a741d24b3011ba5e63413aa7dfae0fc6d506cfba2a3d",
		"000000000000000000000000000000000000000000000000000001",
		"000000000000000000000000000000000000000000000000000002",
		"000000000000000000000000000000000000000000000000000004",
		"00335daa5f18a843aa041449ed112512db558e5e4efe0ab13546c5",
	]
	typealias Vector = (encoded: String, decoded: String)
	private static func vector(at index: Int) -> Vector {
		(encoded: Self.encoded[index], decoded: Self.decoded[index])
	}

	static var vectors: [Vector] {
		precondition(encoded.count == decoded.count)
		return (0 ..< encoded.count).map {
			vector(at: $0)
		}
	}
}
