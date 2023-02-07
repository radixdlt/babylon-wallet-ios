import CryptoKit
@testable import RadixConnect
import TestingPrelude

// MARK: - DataChannelClientTests
@MainActor
final class DataChannelClientTests: TestCase {
	static let numberOfChunks = 3

	let messageID = ChunkedMessagePackage.MessageID(rawValue: UUID().uuidString)
	let testChunksData = try! Data.random(length: MessageSplitter.messageSizeChunkLimitDefault * DataChannelClientTests.numberOfChunks)
	lazy var packages = MessageSplitter().split(message: testChunksData, messageID: messageID)
	var packagesMetaData: ChunkedMessagePackage.MetaDataPackage {
		packages[0].metaData!
	}

	let dataChannel = DataChannelMock()
	let delegate = DataChannelDelegateMock()
	let jsonEncoder = JSONEncoder()
	lazy var client = DataChannelClient(dataChannel: dataChannel, delegate: delegate, idBuilder: { self.messageID })

	func test_sendMessage() async throws {
		try await client.sendMessage(testChunksData)

		// + 1 for MetaData package
		let sentPackagesData = await dataChannel.sentData.prefix(Self.numberOfChunks + 1).collect()

		let sentPackages = try sentPackagesData.map { try JSONDecoder().decode(ChunkedMessagePackage.self, from: $0) }

		XCTAssertEqual(packages, sentPackages)
	}

	// MARK: - ReceiveMessage Happy Paths

	func test_receiveMessageError() async throws {
		let expectedError = ChunkedMessagePackage.ReceiveError(messageId: messageID, error: .messageHashesMismatch)
		try await assertReceivedMessages([.receiveMessageError(expectedError)], expected: .failure(expectedError))
	}

	func assertReceivedMessages(_ packages: [ChunkedMessagePackage], expected: Result<MessageAssembler.IncommingMessage, Error>) async throws {
		try packages.forEach(delegate.receiveIncommingPackage)
		let receivedMessageResult = try await client.receivedMessages.prefix(1).collect().first!

		switch (expected, receivedMessageResult) {
		case let (.success(expectedMessage), .success(receivedMessage)):
			XCTAssertEqual(expectedMessage, receivedMessage)
		case let (.failure(expectedError as ChunkedMessagePackage.ReceiveError), .failure(receivedError as ChunkedMessagePackage.ReceiveError)):
			XCTAssertEqual(expectedError, receivedError)
		case let (.failure(expectedError as MessageAssembler.Error), .failure(receivedError as MessageAssembler.Error)):
			XCTAssertEqual(expectedError, receivedError)
		default:
			XCTFail("Missmatched response, expected: \(expected), received: \(receivedMessageResult)")
		}
	}

	func test_receiveMessageConfirmation() async throws {
		let expectedConfirmation = ChunkedMessagePackage.ReceiveConfirmation(messageId: messageID)
		try await assertReceivedMessages([.receiveMessageConfirmation(expectedConfirmation)], expected: .success(.receiveConfirmation(expectedConfirmation)))
	}

	func test_receiveChunks_happyPath() async throws {
		try await assertReceivedMessages(
			packages,
			expected: .success(.message(
				.init(
					idOfChunks: messageID,
					messageContent: testChunksData,
					messageHash: packagesMetaData.hashOfMessage.data
				)
			))
		)
	}

	func test_receiveChunks_unsortedChunks() async throws {
		try await assertReceivedMessages(
			packages.shuffled(),
			expected: .success(.message(
				.init(
					idOfChunks: messageID,
					messageContent: testChunksData,
					messageHash: packagesMetaData.hashOfMessage.data
				)
			))
		)
	}

	func test_receiveChunks_metaDataIsNotFirst() async throws {
		var packages = packages
		packages.swapAt(0, packages.count - 1)

		try await assertReceivedMessages(
			packages,
			expected: .success(.message(
				.init(
					idOfChunks: messageID,
					messageContent: testChunksData,
					messageHash: packagesMetaData.hashOfMessage.data
				)
			))
		)
	}

	// MARK: - ReceiveMessage Error paths

	func test_receiveChunks_incorrectIndices() async throws {
		// Will replace the last package with a wrong one
		let wrongIndexPackage = ChunkedMessagePackage.chunk(.init(messageId: messageID, chunkIndex: 5, chunkData: Data()))
		let packages = Array(packages.dropLast(1) + [wrongIndexPackage])

		try await assertReceivedMessages(
			packages,
			expected: .failure(MessageAssembler.Error.parseError(.incorrectIndicesOfChunkedPackages))
		)
	}

	func test_receiveChunks_zeroChunks() async throws {
		let metaData = ChunkedMessagePackage.MetaDataPackage(
			messageId: messageID,
			chunkCount: 0,
			messageByteCount: 3,
			hashOfMessage: .deadbeef32Bytes
		)

		try await assertReceivedMessages(
			[.metaData(metaData)],
			expected: .failure(MessageAssembler.Error.parseError(.noPackages))
		)
	}

	func test_receiveChunks_invalidBytesCount() async throws {
		let metaData = ChunkedMessagePackage.MetaDataPackage(
			messageId: messageID,
			chunkCount: 3,
			messageByteCount: 10,
			hashOfMessage: .deadbeef32Bytes
		)

		let packages = packages.replacing([.metaData(packagesMetaData)], with: [ChunkedMessagePackage.metaData(metaData)])

		try await assertReceivedMessages(
			packages,
			expected: .failure(
				MessageAssembler
					.Error
					.messageByteCountMismatch(
						got: testChunksData.count,
						butMetaDataPackageStated: metaData.messageByteCount
					)
			)
		)
	}

	func test_receiveChunks_invalidMessageHash() async throws {
		let metaData = ChunkedMessagePackage.MetaDataPackage(
			messageId: messageID,
			chunkCount: 3,
			messageByteCount: testChunksData.count,
			hashOfMessage: .deadbeef32Bytes
		)

		let packages = packages.replacing([.metaData(packagesMetaData)], with: [ChunkedMessagePackage.metaData(metaData)])

		try await assertReceivedMessages(
			packages,
			expected: .failure(
				MessageAssembler
					.Error
					.hashMismatch(
						calculated: packagesMetaData.hashOfMessage.hex(),
						butExpected: metaData.hashOfMessage.hex()
					)
			)
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
	func receiveIncommingPackage(_ message: ChunkedMessagePackage) throws {
		let data = try JSONEncoder().encode(message)
		onMessageReceivedContinuation.yield(data)
	}
}
