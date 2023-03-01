import ClientPrelude
import Cryptography
import ProfileClient

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
		@Dependency(\.profileClient) var profileClient

		let getCurrentBaseURL: @Sendable () async -> URL = {
			await profileClient.getGatewayAPIEndpointBaseURL()
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

		return Self(
			getNetworkName: { baseURL in
				let response = try await makeRequest(
					responseType: GatewayAPI.GatewayInformationResponse.self,
					baseURL: baseURL,
					timeoutInterval: nil
				) {
					$0.appendingPathComponent("gateway/information")
				}
				return Network.Name(response.ledgerState.network)
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
			accountResourcesByAddress: { @Sendable accountAddress in
				try await post(
					request: GatewayAPI.EntityResourcesRequest(address: accountAddress.address)
				) { @Sendable base in base.appendingPathComponent("entity/resources") }
			},
			accountMetadataByAddress: { @Sendable accountAddress in
				try await post(
					request: GatewayAPI.EntityMetadataRequest(address: accountAddress.address)
				) { @Sendable base in base.appendingPathComponent("entity/metadata") }
			},
			resourcesOverview: { resourcesOverviewRequest in
				try await post(
					request: resourcesOverviewRequest
				) { $0.appendingPathComponent("entity/overview") }
			},
			resourceDetailsByResourceIdentifier: { resourceAddress in
				try await post(
					request: GatewayAPI.EntityDetailsRequest(address: resourceAddress)
				) { $0.appendingPathComponent("entity/details") }
			}, getNonFungibleLocalIds: { accountAddress, resourceAddress in
				try await post(
					request: GatewayAPI.EntityNonFungibleIdsRequestAllOf(
						address: accountAddress.address,
						resourceAddress: resourceAddress
					)
				) { $0.appendingPathComponent("entity/non-fungible/ids") }
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
			}
		)
	}
}
