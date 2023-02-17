import AsyncExtensions
import CryptoKit
import Foundation
import Prelude
import WebRTC

// MARK: - DataChannelClient
actor DataChannelClient: NSObject {
	// Configuration
	private let jsonDecoder: JSONDecoder = .init()
	private let jsonEncoder: JSONEncoder = .init()
	private let dataChannel: DataChannel
	private let delegate: DataChannelDelegate
	private let idBuilder: @Sendable () -> DataChannelMessage.ID

	// MARK: - Streams
	let onMessageReceived: AsyncStream<Data>
	let onReadyState: AsyncStream<DataChannelState>

	private let onMessageReceivedContinuation: AsyncStream<Data>.Continuation
	private let onReadyStateContinuation: AsyncStream<DataChannelState>.Continuation

	private let incommingMessages: AnyAsyncSequence<DataChannelMessage>
	private let incommingReceipts: AnyAsyncSequence<DataChannelMessage.Receipt>
	private let incommingChunks: AnyAsyncSequence<DataChannelMessage.ChunkedMessage>

	lazy var incommingAssembledMessages: AnyAsyncSequence<Result<DataChannelAssembledMessage, Error>> = self.incommingChunks
		.compactMap {
			try await self.handleIncommingChunks($0)
		}
		.mapToResult()
		.handleEvents(onElement: {
			try? await self.sendReceiptForResult($0)
		})
		.eraseToAnyAsyncSequence()

	// Mutable State
	private typealias ChunksWithMetaData = (metaData: DataChannelMessage.ChunkedMessage.MetaDataPackage?,
	                                        chunks: [DataChannelMessage.ChunkedMessage.ChunkPackage])
	private var messagesByID: [DataChannelMessage.ID: ChunksWithMetaData] = [:]

	// MARK: - Initializer

	@Sendable init(
		dataChannel: DataChannel,
		delegate: DataChannelDelegate,
		idBuilder: @Sendable @escaping () -> DataChannelMessage.ID = { .init(rawValue: UUID().uuidString) }
	) {
		self.dataChannel = dataChannel
		self.delegate = delegate
		self.idBuilder = idBuilder
		(onMessageReceived, onMessageReceivedContinuation) = AsyncStream.streamWithContinuation(Data.self)
		(onReadyState, onReadyStateContinuation) = AsyncStream.streamWithContinuation(DataChannelState.self)

		self.incommingMessages = delegate
			.onMessageReceived
			.mapSkippingError {
				try JSONDecoder().decode(DataChannelMessage.self, from: $0)
			} logError: { error in
				loggerGlobal.error("Critical: Could not decode the incomming DataChannel message \(error)")
			}
			.eraseToAnyAsyncSequence()
			.share()
			.eraseToAnyAsyncSequence()

		self.incommingReceipts = self.incommingMessages.compactMap(\.receipt).eraseToAnyAsyncSequence()
		self.incommingChunks = self.incommingMessages.compactMap(\.chunkedMessage).eraseToAnyAsyncSequence()

		super.init()
	}

	func sendMessage(_ data: Data) async throws {
		let id = idBuilder()
		let assembledMessage = DataChannelAssembledMessage(
			message: data,
			id: id
		)

		try assembledMessage.split().forEach {
			try sendMessageOverDataChannel(.chunkedMessage($0))
		}

		// TODO: Add timeout
		try await waitForMessageConfirmation(id)
	}

	// MARK: - Private

	private func sendMessageOverDataChannel(_ message: DataChannelMessage) throws {
		let data = try jsonEncoder.encode(message)
		dataChannel.sendData(data)
	}

	private func sendReceiptForResult(_ result: Result<DataChannelAssembledMessage, Error>) throws {
		switch result {
		case let .success(message):
			try sendMessageOverDataChannel(
				.receipt(.receiveMessageConfirmation(.init(messageId: message.idOfChunks)))
			)
		case let .failure(error as DataChannelMessage.Receipt.ReceiveError):
			try sendMessageOverDataChannel(
				.receipt(.receiveMessageError(error))
			)
		default:
			// NoOp
			break
		}
	}

	private func waitForMessageConfirmation(_ messageID: DataChannelMessage.ID) async throws {
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

	private func handleIncommingChunks(_ chunk: DataChannelMessage.ChunkedMessage) async throws -> DataChannelAssembledMessage? {
		var (metadata, chunks) = messagesByID[chunk.messageID] ?? (metadata: nil, chunks: [])

		func assembleMessage() throws -> DataChannelAssembledMessage? {
			if let metadata, metadata.chunkCount == chunks.count {
				messagesByID.removeValue(forKey: metadata.messageId)
				return try DataChannelAssembledMessage.assembleFrom(chunks: chunks, metaData: metadata)
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
