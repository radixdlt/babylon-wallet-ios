import AsyncExtensions
import CryptoKit
import Foundation
import Prelude

// MARK: - DataChannel
/// This is mainly added to abstract the WebRTC.RTCDataChannel;
/// If in future WebRTC update the RTCDataChannel will expose the API to instantiate it, this protocol can go away.
protocol DataChannel: Sendable {
	func sendData(_ data: Data)
	func close()
}

// MARK: - DataChannelDelegate
/// This is only needed to make RTCDataChannelDelegate to have async API
protocol DataChannelDelegate: Sendable {
	var receivedMessages: AsyncStream<Data> { get }
	func cancel()
}

// MARK: - DataChannelClient
/// The client that manages the communication over RTCDataChannel.
actor DataChannelClient {
	// Configuration
	private let jsonDecoder: JSONDecoder = .init()
	private let jsonEncoder: JSONEncoder = .init()
	private let dataChannel: DataChannel
	private let delegate: DataChannelDelegate
	private let idBuilder: @Sendable () -> Message.ID

	// MARK: - Streams

	private let incommingMessages: AnyAsyncSequence<Message>
	private let incommingReceipts: AnyAsyncSequence<Message.Receipt>
	private let incommingChunks: AnyAsyncSequence<Message.ChunkedMessage>

	lazy var incommingAssembledMessages: AnyAsyncSequence<Result<AssembledMessage, Error>> = self.incommingChunks
		.compactMap(handleIncommingChunks)
		.mapToResult()
		.handleEvents(onElement: {
			try? await self.sendReceiptForResult($0)
		})
		.eraseToAnyAsyncSequence()

	// Mutable State
	private typealias ChunksWithMetaData = (metaData: Message.ChunkedMessage.MetaDataPackage?,
	                                        chunks: [Message.ChunkedMessage.ChunkPackage])
	private var messagesByID: [Message.ID: ChunksWithMetaData] = [:]

	// MARK: - Initializer

	@Sendable init(
		dataChannel: DataChannel,
		delegate: DataChannelDelegate,
		idBuilder: @Sendable @escaping () -> Message.ID = { .init(rawValue: UUID().uuidString) }
	) {
		self.dataChannel = dataChannel
		self.delegate = delegate
		self.idBuilder = idBuilder

		self.incommingMessages = delegate
			.receivedMessages
			.mapSkippingError {
				try JSONDecoder().decode(Message.self, from: $0)
			} logError: { error in
				loggerGlobal.error("Critical: Could not decode the incomming DataChannel message \(error)")
			}
			.eraseToAnyAsyncSequence()
			.share()
			.eraseToAnyAsyncSequence()

		self.incommingReceipts = self.incommingMessages.compactMap(\.receipt).eraseToAnyAsyncSequence()
		self.incommingChunks = self.incommingMessages.compactMap(\.chunkedMessage).eraseToAnyAsyncSequence()
	}

	func sendMessage(_ data: Data) async throws {
		let id = idBuilder()
		let assembledMessage = AssembledMessage(
			message: data,
			id: id
		)

		try assembledMessage.split().forEach {
			try sendMessageOverDataChannel(.chunkedMessage($0))
		}

		// TODO: Add timeout
		try await waitForMessageConfirmation(id)
	}

	func cancel() {
		delegate.cancel()
		dataChannel.close()
	}

	// MARK: - Private

	private func sendMessageOverDataChannel(_ message: Message) throws {
		let data = try jsonEncoder.encode(message)
		dataChannel.sendData(data)
	}

	private func sendReceiptForResult(_ result: Result<AssembledMessage, Error>) throws {
		switch result {
		case let .success(message):
			try sendMessageOverDataChannel(
				.receipt(.receiveMessageConfirmation(.init(messageId: message.idOfChunks)))
			)
		case let .failure(error as Message.Receipt.ReceiveError):
			try sendMessageOverDataChannel(
				.receipt(.receiveMessageError(error))
			)
		default:
			// NoOp
			break
		}
	}

	private func waitForMessageConfirmation(_ messageID: Message.ID) async throws {
		_ = try await incommingReceipts
			.filter { $0.messageID == messageID }
			.prefix(1)
			.map {
				if case let .receiveMessageError(error) = $0 {
					throw error
				}
				return $0
			}
			.collect()
	}

	@Sendable private func handleIncommingChunks(_ chunk: Message.ChunkedMessage) async throws -> AssembledMessage? {
		var (metadata, chunks) = messagesByID[chunk.messageID] ?? (metadata: nil, chunks: [])

		func assembleMessage() throws -> AssembledMessage? {
			if let metadata, metadata.chunkCount == chunks.count {
				messagesByID.removeValue(forKey: metadata.messageId)
				return try AssembledMessage.assembleFrom(chunks: chunks, metaData: metadata)
			}
			messagesByID[chunk.messageID] = (metadata, chunks)
			return nil
		}

		switch chunk {
		case let .metaData(receivedMetadata):
			guard metadata == nil else {
				// Ignore the additional metadata
				return nil
			}
			metadata = receivedMetadata
			return try assembleMessage()
		case let .chunk(chunk):
			chunks.append(chunk)
			return try assembleMessage()
		}
	}
}
