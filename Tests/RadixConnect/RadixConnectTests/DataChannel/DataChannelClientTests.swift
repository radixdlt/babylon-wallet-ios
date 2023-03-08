import CryptoKit
@testable import RadixConnect
import TestingPrelude

// MARK: - DataChannelClientTests
@MainActor
final class DataChannelClientTests: TestCase {
	static let numberOfChunks = 3

	let messageID = DataChannelClient.Message.ID(rawValue: UUID().uuidString)
	let testChunksData = try! Data.random(length: DataChannelClient.AssembledMessage.chunkSize * DataChannelClientTests.numberOfChunks)
	lazy var chunkedMessages = DataChannelClient.AssembledMessage(message: testChunksData, id: messageID).split()
	lazy var assembledMesage = DataChannelClient.AssembledMessage(message: testChunksData, id: messageID)
	lazy var receiveError = DataChannelClient.Message.Receipt.ReceiveError(messageId: messageID, error: .messageHashesMismatch)

	var packagesMetaData: DataChannelClient.Message.ChunkedMessage.MetaDataPackage {
		chunkedMessages[0].metaData!
	}

	let dataChannel = DataChannelMock()
	let delegate = DataChannelDelegateMock()
	let jsonEncoder = JSONEncoder()
	lazy var client = DataChannelClient(dataChannel: dataChannel, delegate: delegate, idBuilder: { self.messageID })

	func test_sendMessage_receiveConfirmation_success() async throws {
		// Stub the message confirmation
		try self.delegate.receiveIncomingMessage(
			.receipt(.receiveMessageConfirmation(.init(messageId: self.messageID)))
		)

		try await client.sendMessage(testChunksData)

		// + 1 for MetaData package
		let sentPackagesData = await dataChannel.sentData.prefix(Self.numberOfChunks + 1).collect()

		let sentPackages = try sentPackagesData.map {
			try JSONDecoder().decode(DataChannelClient.Message.self, from: $0).chunkedMessage!
		}

		XCTAssertEqual(chunkedMessages, sentPackages)
	}

	func test_sendMessage_receiveError_throwsError() async throws {
		// Stub the message confirmation
		try self.delegate.receiveIncomingMessage(
			.receipt(.receiveMessageError(.init(messageId: self.messageID, error: .messageHashesMismatch)))
		)

		do {
			try await client.sendMessage(testChunksData)
			XCTFail("Expected to throw error")
		} catch {}
	}

	// MARK: - ReceiveMessage Happy Paths

	func test_receiveChunks_happyPath() async throws {
		try await assertReceivedMessages(
			chunkedMessages,
			expected: .success(assembledMesage)
		)
		try await assertSendsConfirmationReceipt()
	}

	func test_receiveChunks_unsortedChunks() async throws {
		try await assertReceivedMessages(
			chunkedMessages.shuffled(),
			expected: .success(assembledMesage)
		)
		try await assertSendsConfirmationReceipt()
	}

	func test_receiveChunks_metaDataIsNotFirst() async throws {
		var packages = chunkedMessages
		packages.swapAt(0, packages.count - 1)

		try await assertReceivedMessages(
			packages,
			expected: .success(assembledMesage)
		)

		try await assertSendsConfirmationReceipt()
	}

	// MARK: - ReceiveMessage Error paths

	func test_receiveChunks_incorrectIndices() async throws {
		// Will replace the last package with a wrong one
		let wrongIndexPackage = DataChannelClient.Message.ChunkedMessage.chunk(
			.init(messageId: messageID, chunkIndex: 5, chunkData: Data())
		)
		let packages = Array(chunkedMessages.dropLast(1) + [wrongIndexPackage])

		try await assertReceivedMessages(
			packages,
			expected: .failure(receiveError)
		)
		try await assertSendsErrorReceipt()
	}

	func test_receiveChunks_zeroChunks() async throws {
		let metaData = DataChannelClient.Message.ChunkedMessage.metaData(
			.init(
				messageId: messageID,
				chunkCount: 0,
				messageByteCount: 3,
				hashOfMessage: .deadbeef32Bytes
			)
		)

		try await assertReceivedMessages(
			[metaData],
			expected: .failure(receiveError)
		)
		try await assertSendsErrorReceipt()
	}

	func test_receiveChunks_invalidBytesCount() async throws {
		let metaData = DataChannelClient.Message.ChunkedMessage.metaData(
			.init(
				messageId: messageID,
				chunkCount: 3,
				messageByteCount: 10,
				hashOfMessage: .deadbeef32Bytes
			)
		)

		let packages = chunkedMessages.replacing([.metaData(packagesMetaData)], with: [metaData])

		try await assertReceivedMessages(
			packages,
			expected: .failure(receiveError)
		)

		try await assertSendsErrorReceipt()
	}

	func test_receiveChunks_invalidMessageHash() async throws {
		let metaData = DataChannelClient.Message.ChunkedMessage.metaData(
			.init(
				messageId: messageID,
				chunkCount: 3,
				messageByteCount: testChunksData.count,
				hashOfMessage: .deadbeef32Bytes
			)
		)

		let packages = chunkedMessages.replacing([.metaData(packagesMetaData)], with: [metaData])

		try await assertReceivedMessages(
			packages,
			expected: .failure(receiveError)
		)

		try await assertSendsErrorReceipt()
	}

	func assertReceivedMessages(
		_ messages: [DataChannelClient.Message.ChunkedMessage],
		expected: Result<DataChannelClient.AssembledMessage, Error>
	) async throws {
		try messages.map(DataChannelClient.Message.chunkedMessage).forEach(delegate.receiveIncomingMessage)
		let receivedMessageResult = try await client.IncomingAssembledMessages.first()

		switch (expected, receivedMessageResult) {
		case let (.success(expectedMessage), .success(receivedMessage)):
			XCTAssertEqual(expectedMessage, receivedMessage)
		case let (.failure(expectedError as DataChannelClient.Message.Receipt.ReceiveError),
		          .failure(receivedError as DataChannelClient.Message.Receipt.ReceiveError)):
			XCTAssertEqual(expectedError, receivedError)
		default:
			XCTFail("Missmatched response, expected: \(expected), received: \(receivedMessageResult)")
		}
	}

	func assertSendsErrorReceipt() async throws {
		let sentMessage = try await dataChannel.sentData.first()
		let decodedSentMessage = try JSONDecoder().decode(DataChannelClient.Message.self, from: sentMessage)

		XCTAssertEqual(
			decodedSentMessage,
			.receipt(.receiveMessageError(.init(messageId: messageID, error: .messageHashesMismatch)))
		)
	}

	func assertSendsConfirmationReceipt() async throws {
		let sentMessage = try await dataChannel.sentData.first()
		let decodedSentMessage = try JSONDecoder().decode(DataChannelClient.Message.self, from: sentMessage)

		XCTAssertEqual(
			decodedSentMessage,
			.receipt(.receiveMessageConfirmation(.init(messageId: messageID)))
		)
	}
}
