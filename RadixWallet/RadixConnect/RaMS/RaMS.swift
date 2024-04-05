import Foundation

// MARK: - RaMS
public actor RaMS {
	typealias EncryptionKey = Tagged<RaMS, HexCodable32Bytes>
	private static let encryptionScheme = EncryptionScheme.version1
	let session = URLSession.shared
	let serviceURL = URL(string: "https://radix-connect-relay-dev.rdx-works-main.extratools.works/api/v1")!

	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	/// A **multicasted** async sequence for received message from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	func recieveRequest(onConnectioId password: ConnectionPassword) async throws {
		let connectionID = try! HexCodable32Bytes(.init(data: password.hash()))

		let url = serviceURL.appendingPathComponent("api/dapp-request").appendingPathComponent(
			connectionID.data.hex()
		)
		let (data, response) = try await session.data(from: url)
		guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
			fatalError()
		}

		let decryptionKey = try! EncryptionKey(.init(data: password.data.data))
		let dAppRequest = try! JSONDecoder().decode(DappRequest.self, from: data)

		let decryptedPayload = try Self.encryptionScheme.decrypt(
			data: dAppRequest.request.data,
			decryptionKey: decryptionKey.symmetric
		)

		let request = try JSONDecoder().decode(
			P2P.RTCMessageFromPeer.Request.self,
			from: decryptedPayload
		)

		incomingMessagesSubject.send(.init(result: .success(.request(request)), route: .deepLink(password)))
	}

	func sendResponse(_ response: P2P.RTCOutgoingMessage.Response, password: ConnectionPassword) async throws {
		let connectionID = try! HexCodable32Bytes(.init(data: password.hash()))

		let url = serviceURL.appendingPathComponent("api/dapp-request").appendingPathComponent(
			connectionID.data.hex()
		)
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "POST"
		urlRequest.allHTTPHeaderFields = [
			"accept": "application/json",
			"Content-Type": "application/json",
		]

		let encodedPrimitive = try JSONEncoder().encode(response)

		let encryptionKey = try! EncryptionKey(.init(data: password.data.data))
		let encryptedPrimitive = try Self.encryptionScheme.encrypt(
			data: encodedPrimitive,
			encryptionKey: encryptionKey.symmetric
		)

		let payload = HexCodable(data: encryptedPrimitive)
		let response = DappResponse(response: payload)

		urlRequest.httpBody = try JSONEncoder().encode(response)

		let (data, dataResponse) = try await session.data(for: urlRequest)

		@Dependency(\.openURL) var openURL
		Task {
			await openURL(.init(string: "https://ddjdmrlme9v4i.cloudfront.net/wallet-response")!)
		}
	}
}

extension RaMS.EncryptionKey {
	public var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}
}

extension RaMS {
	struct DappRequest: Decodable {
		let id: String
		let request: HexCodable
	}

	struct DappResponse: Encodable {
		let response: HexCodable
	}
}
