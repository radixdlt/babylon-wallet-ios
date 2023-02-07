import CryptoKit
@testable import RadixConnect
import TestingPrelude

// MARK: - PackagesEncodingDecodingTests
@MainActor
final class PackagesEncodingDecodingTests: TestCase {
	let messageID: ChunkedMessagePackage.MessageID = .init(rawValue: "Id")

	func test_decoding_receiveError() throws {
		let expectedError = ChunkedMessagePackage.receiveMessageError(
			.init(messageId: messageID, error: .messageHashesMismatch)
		)
		try assertDecoding(of: expectedError)
	}

	func test_decoding_receiveMesageConfirmation() throws {
		let expectedConfirmation = ChunkedMessagePackage.receiveMessageConfirmation(
			.init(messageId: messageID)
		)
		try assertDecoding(of: expectedConfirmation)
	}

	func test_decoding_encoding_receiveMetaData() throws {
		let expectedMetaData = ChunkedMessagePackage.metaData(
			.init(
				messageId: messageID,
				chunkCount: 3,
				messageByteCount: 2,
				hashOfMessage: .deadbeef32Bytes
			)
		)

		try assertDecoding(of: expectedMetaData)
		try assertEncoding(of: expectedMetaData)
	}

	func test_decoding_encoding_receiveChunk() throws {
		let expectedChunk = ChunkedMessagePackage.chunk(
			.init(messageId: messageID, chunkIndex: 3, chunkData: Data())
		)
		try assertDecoding(of: expectedChunk)
		try assertEncoding(of: expectedChunk)
	}

	// MARK: - Helpers

	private func assertDecoding(of package: ChunkedMessagePackage, file: StaticString = #filePath, line: UInt = #line) throws {
		let encoded = try JSONEncoder().encode(package.json)
		let decoded = try JSONDecoder().decode(ChunkedMessagePackage.self, from: encoded)
		XCTAssertEqual(package, decoded, file: file, line: line)
	}

	private func assertEncoding(of package: ChunkedMessagePackage, file: StaticString = #filePath, line: UInt = #line) throws {
		let encoded = try JSONEncoder().encode(package)
		let decoded = try JSONDecoder().decode(JSONValue.self, from: encoded)
		XCTAssertEqual(package.json, decoded, file: file, line: line)
	}
}

// MARK: - JSON format According to CAP-21

extension ChunkedMessagePackage.ReceiveError {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("receiveMessageError"),
			"messageId": .string(messageId.rawValue),
			"error": .string(error.rawValue),
		])
	}
}

extension ChunkedMessagePackage.ReceiveConfirmation {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("receiveMessageConfirmation"),
			"messageId": .string(messageId.rawValue),
		])
	}
}

extension ChunkedMessagePackage.MetaDataPackage {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("metaData"),
			"chunkCount": .int(chunkCount),
			"hashOfMessage": .string(hashOfMessage.hex()),
			"messageId": .string(messageId.rawValue),
			"messageByteCount": .int(messageByteCount),
		])
	}
}

extension ChunkedMessagePackage.ChunkPackage {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("chunk"),
			"chunkIndex": .int(chunkIndex),
			"chunkData": .string(chunkData.hex()),
			"messageId": .string(messageId.rawValue),
		])
	}
}

extension ChunkedMessagePackage {
	var json: JSONValue {
		switch self {
		case let .metaData(metaData):
			return metaData.json
		case let .chunk(chunk):
			return chunk.json
		case let .receiveMessageConfirmation(confirmation):
			return confirmation.json
		case let .receiveMessageError(error):
			return error.json
		}
	}
}
