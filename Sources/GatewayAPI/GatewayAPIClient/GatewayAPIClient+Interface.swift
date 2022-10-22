import Common
import CryptoKit
import Foundation
import Profile

public typealias ResourceIdentifier = String
//public struct EntityResourcesResponse: Sendable, Equatable, Decodable {}
//public struct TransactionSubmitRequest: Sendable, Equatable, Encodable {}
//public struct TransactionStatusResponse: Sendable, Equatable, Decodable {}
//public struct EntityDetailsResponseDetails: Sendable, Equatable, Decodable {}
//public struct TransactionStatusRequest: Sendable, Equatable, Encodable {}
//public struct TransactionSubmitResponse: Sendable, Equatable, Decodable {}

// MARK: - GatewayAPIClient
public struct GatewayAPIClient {
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
//	public var submitTransaction: SubmitTransaction
//	public var transactionStatus: GetTransactionStatus

	public init(
		getEpoch: @escaping GetEpoch,
		accountResourcesByAddress: @escaping GetAccountResourcesByAddress,
		resourceDetailsByResourceIdentifier: @escaping GetResourceDetailsByResourceIdentifier
//		submitTransaction: @escaping SubmitTransaction,
//		transactionStatus: @escaping GetTransactionStatus
	) {
		self.getEpoch = getEpoch
		self.accountResourcesByAddress = accountResourcesByAddress
		self.resourceDetailsByResourceIdentifier = resourceDetailsByResourceIdentifier
//		self.submitTransaction = submitTransaction
//		self.transactionStatus = transactionStatus
	}
}

public extension GatewayAPIClient {
	typealias GetEpoch = @Sendable () async throws -> EpochResponse
	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> EntityResourcesResponse
	typealias GetResourceDetailsByResourceIdentifier = @Sendable (GetTokenDetailsRequest) async throws -> EntityDetailsResponseDetails
//	typealias SubmitTransaction = @Sendable (TransactionSubmitRequest) async throws -> TransactionSubmitResponse
//	typealias GetTransactionStatus = @Sendable (TransactionStatusRequest) async throws -> TransactionStatusResponse
}

// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

// MARK: - ExpectedHTTPURLResponse
struct ExpectedHTTPURLResponse: Swift.Error {}

// MARK: - BadHTTPResponseCode
struct BadHTTPResponseCode: Swift.Error {
	let got: Int
	let butExpected = Self.expected
	static let expected = 200
}

public extension GatewayAPIClient {
	static func live(
		baseURL: URL = .init(string: "https://alphanet.radixdlt.com/v0")!,
		urlSession: URLSession = .shared,
		jsonEncoder: JSONEncoder = .init(),
		jsonDecoder: JSONDecoder = .init()
	) -> Self {
		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			responseType _: Response.Type,
			urlFromBase: (URL) -> URL
		) async throws -> Response where Response: Decodable {
			let url = urlFromBase(baseURL)
			print("📡 🛰 Network request: \(url.absoluteString)")
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = method
			if let httpBody {
				urlRequest.httpBody = httpBody
			}

			urlRequest.allHTTPHeaderFields = [
				"Content-Type": "application/json",
			]

			let (data, urlResponse) = try await urlSession.data(for: urlRequest)

			guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
				throw ExpectedHTTPURLResponse()
			}

			guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
				throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
			}

			let response = try jsonDecoder.decode(Response.self, from: data)

			return response
		}

		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			urlFromBase: @escaping (URL) -> URL
		) async throws -> Response where Response: Decodable {
			try await makeRequest(
				httpBodyData: httpBody,
				method: method,
				responseType: Response.self,
				urlFromBase: urlFromBase
			)
		}

		@Sendable
		func post<Response>(
            urlFromBase: @escaping (URL) -> URL
        ) async throws -> Response where Response: Decodable {
			try await makeRequest(httpBodyData: nil, responseType: Response.self, urlFromBase: urlFromBase)
		}

		@Sendable
		func post<Request, Response>(
			request: Request,
            urlFromBase: @escaping (URL) -> URL
		) async throws -> Response
			where
			Request: Encodable, Response: Decodable
		{
			let httpBody = try jsonEncoder.encode(request)

			return try await makeRequest(httpBodyData: httpBody, urlFromBase: urlFromBase)
		}

		let getEpoch: GetEpoch = {
			try await post {
				$0
					.appendingPathComponent("state")
					.appendingPathComponent("epoch")
			}
		}

		return Self(
			getEpoch: getEpoch,
			accountResourcesByAddress: { accountAddress in
				let epoch = try await getEpoch()
				let request = EntityResourcesRequest(
					address: accountAddress.address,
					atStateIdentifier: PartialLedgerStateIdentifier(
						stateVersion: 0,
						timestamp: Date(),
						epoch: epoch.epoch,
						round: 0
					)
				)
				return try await post(request: request) { baseURL in
                    baseURL
                        .appendingPathComponent("state")
                        .appendingPathComponent("resources")
                }

			},
			resourceDetailsByResourceIdentifier: { resourceAddress in
                let epoch = try await getEpoch()
                let request = ResourceIdentifier.init
                return try await post(request: request) { baseURL in
                    baseURL
                        .appendingPathComponent("state")
                        .appendingPathComponent("resources")
                }
			}
//			submitTransaction: { transactionSubmitRequest in
//				try await Self.mock().submitTransaction(transactionSubmitRequest)
//			},
//			transactionStatus: { transactionStatusRequest in
//				try await Self.mock().transactionStatus(transactionStatusRequest)
//			}
		)
	}
}
