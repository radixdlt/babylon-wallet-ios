@testable import P2PConnection
import TestingPrelude

final class ChunkingTransportUnitTests: XCTestCase {
	func test_split_reassemble() throws {
		let longMessage = "A message that is long, " + String(repeating: "very ", count: 10000) + "long."

		let splitter = MessageSplitter(messageSizeChunkLimit: 1000)
		let assembler = ChunkedMessagePackageAssembler()

		let packages = try splitter.split(
			message: longMessage.data(using: .utf8)!,
			messageID: "an id"
		)

		let reassembled = try assembler.assemble(packages: packages).messageContent

		XCTAssertEqual(String(data: reassembled, encoding: .utf8)!, longMessage)
	}
}
