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

	func test_decode1() throws {
		let decodeRequest = DecodeAddressRequest(
			address: "account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt"
		)
		let decodeResponse = try sut.decodeAddressRequest(request: decodeRequest).get()
		XCTAssertEqual(decodeResponse.data.hex, "07dea02f0a5efd1bd1a4f9d03ba8273267840d3f5f512dfbadfa23968df9")
	}

	func test_decode2() throws {
		let decodeRequest = DecodeAddressRequest(
			address: "account_sim1ql02qtc2tm73h5dyl8grh2p8xfncgrfltagjm7adlg3edr0ejjmpvt"
		)
		// TODO: Update - how to determine the pubkey data from the address?
//		let decodeResponse = try sut.decodeAddressRequest(request: decodeRequest).get()
//		let pubkeyData = "b9c37926187c6ecfee40577e29942ecc1371c5bb6350288aca92033b16ce595c"
//		let hash = try Data(hex: sut.hashRequest(request: .init(payload: pubkeyData)).get().value).suffix(26)
//		XCTAssertEqual(decodeResponse.data.suffix(26).hex, hash.hex)
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

		let decoded = try sut.decodeAddressRequest(request: decodeRequest).get()

		XCTAssertNoThrow(decoded)

		let encodeRequest = try EncodeAddressRequest(
			addressHex: vector.decoded,
			networkId: networkID
		)
		let encoded = try sut.encodeAddressRequest(request: encodeRequest).get()
		XCTAssertNoDifference(encoded.address.address, vector.encoded)
	}

	fileprivate typealias TestSuite = AddressDecodeEncodeTestVectors
}

// MARK: - AddressDecodeEncodeTestVectors
enum AddressDecodeEncodeTestVectors {
	private static let encoded: [String] = [
		"resource_sim1q2atsr8kvzrkdpqe7h94jp9vleraasdw348gn8zg9g6n6g50t6hwlp",
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
		"02bab80cf66087668419f5cb5904acfe47dec1ae8d4e899c482a353d228f",
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
