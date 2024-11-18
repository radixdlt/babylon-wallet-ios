// MARK: - Date + @unchecked Sendable
extension Date: @unchecked Sendable {}

extension JSONDecoder {
	static var `default`: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
		return decoder
	}
}

extension GatewayAPIClient {
	struct EmptyEntityDetailsResponse: Error {}
	typealias SingleEntityDetailsResponse = (ledgerState: GatewayAPI.LedgerState, details: GatewayAPI.StateEntityDetailsResponseItem)
	typealias Value = GatewayAPIClient

	static let liveValue = GatewayAPIClient.live(
		jsonEncoder: .init(),
		jsonDecoder: .default
	)

	static func live(
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

			urlRequest.setHttpHeaderFields()

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
		func getEntityDetails(_ addresses: [String], optIns: GatewayAPI.StateEntityDetailsOptIns?, ledgerState: GatewayAPI.LedgerStateSelector?) async throws -> GatewayAPI.StateEntityDetailsResponse {
			assert(optIns?.explicitMetadata?.count ?? 0 <= EntityMetadataKey.maxAllowedKeys)
			return try await post(
				request: GatewayAPI.StateEntityDetailsRequest(
					atLedgerState: ledgerState,
					optIns: optIns,
					addresses: addresses, aggregationLevel: .vault
				)) { @Sendable base in base.appendingPathComponent("state/entity/details") }
		}

		@Sendable
		func getSingleEntityDetails(
			_ address: String,
			explicitMetadata: Set<EntityMetadataKey>
		) async throws -> SingleEntityDetailsResponse {
			let response = try await getEntityDetails([address], optIns: .init(explicitMetadata: explicitMetadata.map(\.rawValue)), ledgerState: nil)
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
				return NetworkDefinition.Name(response.ledgerState.network)
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
				try await getSingleEntityDetails(address, explicitMetadata: explicitMetadata).details.metadata
			},
			getEntityMetadataPage: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("state/entity/page/metadata/") }
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
			getAccountLockerTouchedAt: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("/state/account-lockers/touched-at") }
			},
			getAccountLockerVaults: { request in
				try await post(
					request: request
				) { $0.appendingPathComponent("/state/account-locker/page/vaults") }
			},
			streamTransactions: { streamTransactionsRequest in
				try await post(
					request: streamTransactionsRequest,
					dateEncodingStrategy: .iso8601
				) { $0.appendingPathComponent("stream/transactions") }
			},
			prevalidateDeposit: { prevalidateDepositRequest in
				try await post(
					request: prevalidateDepositRequest
				) { $0.appendingPathComponent("transaction/account-deposit-pre-validation") }
			}
		)
	}
}
