import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import Foundation
import Profile
import ProfileClient
import SLIP10
import URLBuilderClient

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

extension JSONDecoder {
	static var `default`: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
		return decoder
	}
}

public extension GatewayAPIClient {
	typealias Value = GatewayAPIClient
	static let liveValue = GatewayAPIClient.live(
		urlSession: .shared,
		jsonEncoder: .init(),
		jsonDecoder: .default
	)

	static func live(
		urlSession: URLSession,
		jsonEncoder: JSONEncoder,
		jsonDecoder: JSONDecoder
	) -> Self {
		@Dependency(\.profileClient) var profileClient
		@Dependency(\.urlBuilder) var urlBuilder

		let getCurrentBaseURL: GetCurrentBaseURL = {
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
		func getGatewayInfo(baseURL: URL, timeoutInterval: TimeInterval?) async throws -> GatewayAPI.GatewayInfoResponse {
			try await makeRequest(
				responseType: GatewayAPI.GatewayInfoResponse.self,
				baseURL: baseURL,
				timeoutInterval: timeoutInterval
			) {
				$0.appendingPathComponent("gateway")
			}
		}

		@Sendable
		func getNetworkName(baseURL: URL) async throws -> Network.Name {
			let gatewayInfo = try await getGatewayInfo(baseURL: baseURL, timeoutInterval: 2)
			return Network.Name(rawValue: gatewayInfo.ledgerState.network)
		}

		let setCurrentBaseURL: SetCurrentBaseURL = { @Sendable newURL in
			let currentURL = await getCurrentBaseURL()
			guard newURL != currentURL else {
				return nil
			}
			let name = try await getNetworkName(baseURL: newURL)
			// FIXME: also compare `NetworkID` from lookup with NetworkID from `getNetworkInformation` call
			// once it returns networkID!
			let network = try Network.lookupBy(name: name)

			let networkAndGateway = AppPreferences.NetworkAndGateway(
				network: network,
				gatewayAPIEndpointURL: newURL
			)

			try await profileClient.setNetworkAndGateway(networkAndGateway)

			return networkAndGateway
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

		let getGatewayInfo: GetGatewayInfo = { try await getGatewayInfo(baseURL: getCurrentBaseURL(), timeoutInterval: nil) }

		return Self(
			getCurrentBaseURL: getCurrentBaseURL,
			setCurrentBaseURL: setCurrentBaseURL,
			getGatewayInfo: getGatewayInfo,
			getEpoch: {
				try await Epoch(rawValue: .init(getGatewayInfo().ledgerState.epoch))
			},
			accountResourcesByAddress: { @Sendable accountAddress in
				try await post(
					request: GatewayAPI.EntityResourcesRequest(address: accountAddress.address)
				) { @Sendable base in base.appendingPathComponent("entity/resources") }
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
			},
			recentTransactions: { recentTransactionsRequest in
				try await post(
					request: recentTransactionsRequest
				) { $0.appendingPathComponent("transaction/recent") }
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
			transactionDetails: { transactionDetailsRequest in
				try await post(
					request: transactionDetailsRequest
				) { $0.appendingPathComponent("transaction/details") }
			}
		)
	}
}
