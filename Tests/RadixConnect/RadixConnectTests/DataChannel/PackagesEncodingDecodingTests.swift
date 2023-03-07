import CryptoKit
@testable import RadixConnect
import TestingPrelude

// MARK: - DataChannelMessageEncodingDecodingTests
@MainActor
final class DataChannelMessageEncodingDecodingTests: TestCase {
	let messageID: DataChannelClient.Message.ID = .init(rawValue: "Id")

	func test_decoding_receiveError() throws {
		let expectedError = DataChannelClient.Message.receipt(.receiveMessageError(
			.init(messageId: messageID, error: .messageHashesMismatch)
		))
		try assertDecoding(of: expectedError)
	}

	func test_decoding_receiveMesageConfirmation() throws {
		let expectedConfirmation = DataChannelClient.Message.receipt(.receiveMessageConfirmation(
			.init(messageId: messageID)
		))
		try assertDecoding(of: expectedConfirmation)
	}

	func test_decoding_encoding_receiveMetaData() throws {
		let expectedMetaData = DataChannelClient.Message.chunkedMessage(.metaData(
			.init(
				messageId: messageID,
				chunkCount: 3,
				messageByteCount: 2,
				hashOfMessage: .deadbeef32Bytes
			)
		))

		try assertDecoding(of: expectedMetaData)
		try assertEncoding(of: expectedMetaData)
	}

	func test_decoding_encoding_receiveChunk() throws {
		let expectedChunk = DataChannelClient.Message.chunkedMessage(.chunk(
			.init(messageId: messageID, chunkIndex: 3, chunkData: Data())
		))
		try assertDecoding(of: expectedChunk)
		try assertEncoding(of: expectedChunk)
	}

	// MARK: - Helpers

	private func assertDecoding(of message: DataChannelClient.Message, file: StaticString = #filePath, line: UInt = #line) throws {
		let encoded = try JSONEncoder().encode(message.json)
		let decoded = try JSONDecoder().decode(DataChannelClient.Message.self, from: encoded)
		XCTAssertEqual(message, decoded, file: file, line: line)
	}

	private func assertEncoding(of message: DataChannelClient.Message, file: StaticString = #filePath, line: UInt = #line) throws {
		let encoded = try JSONEncoder().encode(message)
		let decoded = try JSONDecoder().decode(JSONValue.self, from: encoded)
		XCTAssertEqual(message.json, decoded, file: file, line: line)
	}
}

// MARK: - JSON format According to CAP-21

extension DataChannelClient.Message.Receipt.ReceiveError {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("receiveMessageError"),
			"messageId": .string(messageId.rawValue),
			"error": .string(error.rawValue),
		])
	}
}

extension DataChannelClient.Message.Receipt.ReceiveConfirmation {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("receiveMessageConfirmation"),
			"messageId": .string(messageId.rawValue),
		])
	}
}

extension DataChannelClient.Message.ChunkedMessage.MetaDataPackage {
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

extension DataChannelClient.Message.ChunkedMessage.ChunkPackage {
	var json: JSONValue {
		.dictionary([
			"packageType": .string("chunk"),
			"chunkIndex": .int(chunkIndex),
			"chunkData": .string(chunkData.hex()),
			"messageId": .string(messageId.rawValue),
		])
	}
}

extension DataChannelClient.Message {
	var json: JSONValue {
		switch self {
		case let .chunkedMessage(.metaData(metaData)):
			return metaData.json
		case let .chunkedMessage(.chunk(chunk)):
			return chunk.json
		case let .receipt(.receiveMessageConfirmation(confirmation)):
			return confirmation.json
		case let .receipt(.receiveMessageError(error)):
			return error.json
		}
	}
}
