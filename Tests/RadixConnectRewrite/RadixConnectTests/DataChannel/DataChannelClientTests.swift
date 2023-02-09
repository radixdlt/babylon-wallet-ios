import CryptoKit
@testable import RadixConnect
import TestingPrelude

// MARK: - DataChannelClientTests
@MainActor
final class DataChannelClientTests: TestCase {
	static let numberOfChunks = 3

	let messageID = DataChannelMessage.ID(rawValue: UUID().uuidString)
	let testChunksData = try! Data.random(length: DataChannelAssembledMessage.chunkSize * DataChannelClientTests.numberOfChunks)
        lazy var chunkedMessages = DataChannelAssembledMessage(message: testChunksData, id: messageID).split()
        lazy var assembledMesage = DataChannelAssembledMessage(message: testChunksData, id: messageID)
        lazy var receiveError = DataChannelMessage.Receipt.ReceiveError(messageId: messageID, error: .messageHashesMismatch)

        var packagesMetaData: DataChannelMessage.ChunkedMessage.MetaDataPackage {
                chunkedMessages[0].metaData!
	}


	let dataChannel = DataChannelMock()
	let delegate = DataChannelDelegateMock()
	let jsonEncoder = JSONEncoder()
	lazy var client = DataChannelClient(dataChannel: dataChannel, delegate: delegate, idBuilder: { self.messageID })

	func test_sendMessage_receiveConfirmation_success() async throws {
                // Stub the message confirmation
                try self.delegate.receiveIncommingMessage(
                        .receipt(.receiveMessageConfirmation(.init(messageId: self.messageID)))
                )
                
		try await client.sendMessage(testChunksData)

		// + 1 for MetaData package
		let sentPackagesData = await dataChannel.sentData.prefix(Self.numberOfChunks + 1).collect()

                let sentPackages = try sentPackagesData.map {
                        try JSONDecoder().decode(DataChannelMessage.self, from: $0).chunkedMessage!
                }

		XCTAssertEqual(chunkedMessages, sentPackages)
	}

        func test_sendMessage_receiveError_throwsError() async throws {
                // Stub the message confirmation
                try self.delegate.receiveIncommingMessage(
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
                let wrongIndexPackage = DataChannelMessage.ChunkedMessage.chunk(
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
                let metaData = DataChannelMessage.ChunkedMessage.metaData(
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
                let metaData = DataChannelMessage.ChunkedMessage.metaData(
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
                let metaData = DataChannelMessage.ChunkedMessage.metaData(
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
                _ messages: [DataChannelMessage.ChunkedMessage],
                expected: Result<DataChannelAssembledMessage, Error>
        ) async throws {
                try messages.map(DataChannelMessage.chunkedMessage).forEach(delegate.receiveIncommingMessage)
                let receivedMessageResult = try await client.incommingAssembledMessages.prefix(1).collect().first!

                switch (expected, receivedMessageResult) {
                case let (.success(expectedMessage), .success(receivedMessage)):
                        XCTAssertEqual(expectedMessage, receivedMessage)
                case let (.failure(expectedError as DataChannelMessage.Receipt.ReceiveError),
                          .failure(receivedError as DataChannelMessage.Receipt.ReceiveError)):
                        XCTAssertEqual(expectedError, receivedError)
                default:
                        XCTFail("Missmatched response, expected: \(expected), received: \(receivedMessageResult)")
                }
        }

        func assertSendsErrorReceipt() async throws {
                let sentMessage = await dataChannel.sentData.prefix(1).collect().first!
                let decodedSentMessage = try JSONDecoder().decode(DataChannelMessage.self, from: sentMessage)

                XCTAssertEqual(
                        decodedSentMessage,
                                .receipt(.receiveMessageError(.init(messageId: messageID, error: .messageHashesMismatch)))
                )
        }

        func assertSendsConfirmationReceipt() async throws {
                let sentMessage = await dataChannel.sentData.prefix(1).collect().first!
                let decodedSentMessage = try JSONDecoder().decode(DataChannelMessage.self, from: sentMessage)

                XCTAssertEqual(
                        decodedSentMessage,
                        .receipt(.receiveMessageConfirmation(.init(messageId: messageID)))
                )
        }
}

extension Data {
	static func random(length: Int) throws -> Data {
		Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
	}
}

// MARK: - DataChannelMock
final class DataChannelMock: DataChannel {
	let sentData: AsyncStream<Data>
	private let sentDataContinuation: AsyncStream<Data>.Continuation

	init() {
		(sentData, sentDataContinuation) = AsyncStream<Data>.streamWithContinuation()
	}

	func sendData(_ data: Data) {
		sentDataContinuation.yield(data)
	}

	func close() {}
}

// MARK: - DataChannelDelegateMock
final class DataChannelDelegateMock: DataChannelDelegate, Sendable {
	let onMessageReceived: AsyncStream<Data>
	let onReadyState: AsyncStream<DataChannelState>

	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation
	private let onReadyStateContinuation: AsyncStream<DataChannelState>.Continuation

	init() {
		(onMessageReceived, onMessageReceivedContinuation) = AsyncStream<Data>.streamWithContinuation()
		(onReadyState, onReadyStateContinuation) = AsyncStream<DataChannelState>.streamWithContinuation()
	}
}

extension DataChannelDelegateMock {
	func receiveIncommingMessage(_ message: DataChannelMessage) throws {
		let data = try JSONEncoder().encode(message)
		onMessageReceivedContinuation.yield(data)
	}
}
