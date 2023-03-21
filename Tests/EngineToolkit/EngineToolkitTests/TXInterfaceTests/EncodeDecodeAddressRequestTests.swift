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
		"resource_sim1q2ym536cwvvf3cy9p777t4qjczqwf79hagp3wn93srvsgvqtwe",
		"account_sim1qspjlnwx4gdcazhral74rjgzgysrslf8ngrfmprecrrss3p9md",
		"package_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqqkul8u2",
		"resource_sim1q88ghe0tnzqqc90xjskj0cmntxwp3gv7pzjnx7p5r54qyze494",
		"resource_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs9m9ls9",
		"resource_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqps2x29mr",
		"resource_sim1qy7rfwzgm99jp4lwngv8utfnzxd7zv2fq9p279rzzmwszdz4ua",
		"resource_sim1q8jy0frw4en9cdc63cyj2n7pdefj95lftvrdamjhhyqqf3x7h5",
		"component_sim1qv0z2nsg5aqayjeszxa9uc6p82nalts0cm2sdna69g7sxph27u",
		"package_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqspl7gsp",
		"package_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqmre2w5",
		"package_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzq2dgdn7",
		"package_sim1qqe4m2jlrz5y82syz3y76yf9ztd4trj7fmlq4vf4gmzslrcpvj",
	]

	private static let decoded: [String] = [
		"0289ba4758731898e0850fbde5d412c080e4f8b7ea03174cb180d9",
		"04032fcdc6aa1b8e8ae3effd51c9024120387d279a069d8479c0c7",
		"000000000000000000000000000000000000000000000000000040",
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
