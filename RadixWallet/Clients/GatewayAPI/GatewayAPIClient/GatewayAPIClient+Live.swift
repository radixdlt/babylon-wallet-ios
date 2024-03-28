// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

extension JSONDecoder {
	static var `default`: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
		return decoder
	}
}

private var rdxClientVersion: String? {
	guard
		let mainBundleInfoDictionary = Bundle.main.infoDictionary,
		let version = mainBundleInfoDictionary["CFBundleShortVersionString"] as? String,
		let buildNumber = mainBundleInfoDictionary["CFBundleVersion"] as? String
	else {
		return nil
	}

	return version
		+ "#" + buildNumber
		+ "-" + (BuildConfiguration.current?.description ?? "UNKNOWN")
}

extension GatewayAPIClient {
	public struct EmptyEntityDetailsResponse: Error {}
	public typealias SingleEntityDetailsResponse = (ledgerState: GatewayAPI.LedgerState, details: GatewayAPI.StateEntityDetailsResponseItem)
	public typealias Value = GatewayAPIClient

	public static let liveValue = GatewayAPIClient.live(
		jsonEncoder: .init(),
		jsonDecoder: .default
	)

	public static func live(
		jsonEncoder: JSONEncoder,
		jsonDecoder: JSONDecoder
	) -> Self {
		@Dependency(\.gatewaysClient) var gatewaysClient
		@Dependency(\.httpClient) var httpClient

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
				"RDX-Client-Name": "iOS Wallet",
				"RDX-Client-Version": rdxClientVersion ?? "UNKNOWN",
			]
			if let timeoutInterval {
				urlRequest.timeoutInterval = timeoutInterval
			}

			let data = try await httpClient.executeRequest(urlRequest)

			do {
				return try jsonDecoder.decode(Response.self, from: data)
			} catch {
				throw ResponseDecodingError(receivedData: data, error: error)
			}
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
		func post<Response>(
			request: some Encodable,
			dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
			urlFromBase: @escaping @Sendable (URL) -> URL
		) async throws -> Response where Response: Decodable {
			jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
			jsonEncoder.dateEncodingStrategy = dateEncodingStrategy
			let httpBody = try jsonEncoder.encode(request)
			return try await makeRequest(httpBodyData: httpBody, urlFromBase: urlFromBase)
		}

		@Sendable
		func getEntityDetails(_ addresses: [String], explictMetadata: Set<EntityMetadataKey>, ledgerState: GatewayAPI.LedgerStateSelector?) async throws -> GatewayAPI.StateEntityDetailsResponse {
			assert(explictMetadata.count <= EntityMetadataKey.maxAllowedKeys)
			return try await post(
				request: GatewayAPI.StateEntityDetailsRequest(
					atLedgerState: ledgerState,
					optIns: .init(
						explicitMetadata: explictMetadata.map(\.rawValue)
					),
					addresses: addresses, aggregationLevel: .vault
				)) { @Sendable base in base.appendingPathComponent("state/entity/details") }
		}

		@Sendable
		func getSingleEntityDetails(
			_ address: String,
			explictMetadata: Set<EntityMetadataKey>
		) async throws -> SingleEntityDetailsResponse {
			let response = try await getEntityDetails([address], explictMetadata: explictMetadata, ledgerState: nil)
			guard let item = response.items.first else {
				throw EmptyEntityDetailsResponse()
			}

			return (response.ledgerState, item)
		}

		return GatewayAPIClient(
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
				return Epoch(response.ledgerState.epoch)
			},
			getEntityDetails: getEntityDetails,
			getEntityMetadata: { address, explicitMetadata in
				try await getSingleEntityDetails(address, explictMetadata: explicitMetadata).details.metadata
			},
			getEntityFungiblesPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/fungibles/") }
			},
			getEntityFungibleResourceVaultsPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/fungible-vaults/") }
			},
			getEntityNonFungiblesPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/non-fungibles/") }
			},
			getEntityNonFungibleResourceVaultsPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/non-fungible-vaults/") }
			},
			getEntityNonFungibleIdsPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/non-fungible-vault/ids") }
			},
			getNonFungibleData: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/non-fungible/data") }
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
			},
			streamTransactions: { streamTransactionsRequest in
				try await post(
					request: streamTransactionsRequest,
					dateEncodingStrategy: .iso8601
				) { $0.appendingPathComponent("stream/transactions") }
			}
		)
	}
}
