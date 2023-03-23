import ClientPrelude
import Cryptography
import GatewaysClient

// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

extension JSONDecoder {
	static var `default`: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
		return decoder
	}
}

extension GatewayAPIClient {
	public struct EmptyEntityDetailsResponse: Error {}
	public typealias SingleEntityDetailsResponse = (ledgerState: GatewayAPI.LedgerState, details: GatewayAPI.StateEntityDetailsResponseItem)
	public typealias Value = GatewayAPIClient

	public static let liveValue = GatewayAPIClient.live(
		urlSession: .shared,
		jsonEncoder: .init(),
		jsonDecoder: .default
	)

	public static func live(
		urlSession: URLSession,
		jsonEncoder: JSONEncoder,
		jsonDecoder: JSONDecoder
	) -> Self {
		@Dependency(\.gatewaysClient) var gatewaysClient

		let getCurrentBaseURL: @Sendable () async -> URL = {
			await gatewaysClient.getGatewayAPIEndpointBaseURL()
		}

		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data? = nil,
			method: String = "POST",
			responseType _: Response.Type,
			baseURL: URL,
			timeoutInterval: TimeInterval? = nil,
			urlFromBase: @Sendable (URL) -> URL
		) async throws -> Response where Response: Decodable {
			let url = urlFromBase(baseURL)
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = method
			if let httpBody {
				urlRequest.httpBody = httpBody
			}

			urlRequest.allHTTPHeaderFields = [
				"accept": "application/json",
				"Content-Type": "application/json",
			]
			if let timeoutInterval {
				urlRequest.timeoutInterval = timeoutInterval
			}

			let (data, urlResponse) = try await urlSession.data(for: urlRequest)

			guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
				throw ExpectedHTTPURLResponse()
			}

			guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
				#if DEBUG
				loggerGlobal.error("Request with URL: \(urlRequest.url!.absoluteString) failed with status code: \(httpURLResponse.statusCode), data: \(data.prettyPrintedJSONString ?? "<NOT_JSON>")")
				#endif
				throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
			}

			let response = try jsonDecoder.decode(Response.self, from: data)

			return response
		}

		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			responseType: Response.Type,
			urlFromBase: @escaping @Sendable (URL) -> URL
		) async throws -> Response where Response: Decodable {
			try await makeRequest(
				httpBodyData: httpBody,
				method: method,
				responseType: responseType,
				baseURL: getCurrentBaseURL(),
				urlFromBase: urlFromBase
			)
		}

		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			urlFromBase: @escaping @Sendable (URL) -> URL
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
			urlFromBase: @escaping @Sendable (URL) -> URL
		) async throws -> Response where Response: Decodable {
			try await makeRequest(httpBodyData: nil, responseType: Response.self, urlFromBase: urlFromBase)
		}

		@Sendable
		func post<Request, Response>(
			request: Request,
			urlFromBase: @escaping @Sendable (URL) -> URL
		) async throws -> Response
			where
			Request: Encodable, Response: Decodable
		{
			jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
			let httpBody = try jsonEncoder.encode(request)

			return try await makeRequest(httpBodyData: httpBody, urlFromBase: urlFromBase)
		}

		@Sendable
		func getEntityDetails(_ addresses: [String]) async throws -> GatewayAPI.StateEntityDetailsResponse {
			try await post(
				request: GatewayAPI.StateEntityDetailsRequest(addresses: addresses)
			) { @Sendable base in base.appendingPathComponent("state/entity/details") }
		}

		@Sendable
		func getSingleEntityDetails(_ address: String) async throws -> SingleEntityDetailsResponse {
			let response = try await getEntityDetails([address])
			guard let item = response.items.first else {
				throw EmptyEntityDetailsResponse()
			}

			return (response.ledgerState, item)
		}

		return Self(
			getNetworkName: { baseURL in
				let response = try await makeRequest(
					responseType: GatewayAPI.GatewayStatusResponse.self,
					baseURL: baseURL,
					timeoutInterval: nil
				) {
					$0.appendingPathComponent("status/gateway-status")
				}
				return Radix.Network.Name(response.ledgerState.network)
			},
			getEpoch: {
				let response = try await makeRequest(
					responseType: GatewayAPI.TransactionConstructionResponse.self,
					baseURL: getCurrentBaseURL(),
					timeoutInterval: nil
				) {
					$0.appendingPathComponent("transaction/construction")
				}
				return Epoch(rawValue: .init(response.ledgerState.epoch))
			},
			getEntityDetails: getEntityDetails,
			getAccountDetails: { accountAddress in
				try await getSingleEntityDetails(accountAddress.address)
			},
			getEntityMetadata: { address in
				try await getSingleEntityDetails(address).details.metadata
			},
			getNonFungibleIds: { resourceAddress in
				try await post(
					request: GatewayAPI.StateNonFungibleIdsRequest(resourceAddress: resourceAddress)
				) { $0.appendingPathComponent("state/non-fungible/ids") }
			},
			submitTransaction: { transactionSubmitRequest in
				try await post(
					request: transactionSubmitRequest
				) { $0.appendingPathComponent("transaction/submit") }
			},
			transactionStatus: { transactionStatusRequest in
				try await post(
					request: transactionStatusRequest
				) { $0.appendingPathComponent("transaction/status") }
			},
			transactionPreview: { transactionPreviewRequest in
				try await post(
					request: transactionPreviewRequest
				) { $0.appendingPathComponent("transaction/preview") }
			}
		)
	}
}
