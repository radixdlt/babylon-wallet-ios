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

// MARK: - PollStrategy
public struct PollStrategy {
	public let maxPollTries: Int
	public let sleepDuration: TimeInterval
	public init(maxPollTries: Int, sleepDuration: TimeInterval) {
		self.maxPollTries = maxPollTries
		self.sleepDuration = sleepDuration
	}

	public static let `default` = Self(maxPollTries: 20, sleepDuration: 2)
}

// MARK: - GatewayAPI.TransactionDetailsResponse + Sendable
extension GatewayAPI.TransactionDetailsResponse: @unchecked Sendable {}

// MARK: - GatewayAPI.TransactionStatus.Status + Sendable
extension GatewayAPI.TransactionStatus.Status: @unchecked Sendable {}

// MARK: - FailedToGetDetailsOfSuccessfullySubmittedTX
struct FailedToGetDetailsOfSuccessfullySubmittedTX: LocalizedError, Equatable {
	public let txID: TXID
	var errorDescription: String? {
		"Successfully submitted TX with txID: \(txID) but failed to get transaction details for it."
	}
}

// MARK: - SuccessfullySubmittedTransaction
public struct SuccessfullySubmittedTransaction: Sendable, Hashable {
	private let txDetails: GatewayAPI.TransactionDetailsResponse?
	public let txID: TXID
	public func details() throws -> GatewayAPI.TransactionDetailsResponse {
		guard let txDetails else {
			throw FailedToGetDetailsOfSuccessfullySubmittedTX(txID: txID)
		}
		return txDetails
	}

	public init(txDetails: GatewayAPI.TransactionDetailsResponse?, txID: TXID) {
		self.txDetails = txDetails
		self.txID = txID
	}
}

#if DEBUG
public extension SuccessfullySubmittedTransaction {
	static let placeholder: Self = .init(txDetails: .init(ledgerState: .init(network: "placeholder", stateVersion: 1, timestamp: "time", epoch: 1, round: 1), transaction: .init(transactionStatus: .init(status: .succeeded), payloadHashHex: "placeholder", intentHashHex: "placeholder"), details: .init(rawHex: "placeholder", referencedGlobalEntities: [])), txID: "placeholder")
}
#endif // DEBUG

// MARK: - SubmitTXFailure
// FIXME: - mainnet: improve hanlding of polling failure
/// This failure might be a false positive, due to i.e. POLLING of tx failed, but TX might have
/// been submitted successfully. Or we might have successfully submitted the TX but failed to get details about it.
public enum SubmitTXFailure: Sendable, LocalizedError, Equatable {
	case failedToSubmitTX
	case invalidTXWasDuplicate

	/// Failed to poll, maybe TX was submitted successfuly?
	case failedToPollTX(txID: TXID, error: FailedToPollError)

	case failedToGetTransactionStatus(txID: TXID, error: FailedToGetTransactionStatus)
	case invalidTXWasSubmittedButNotSuccessful(txID: TXID, status: GatewayAPI.TransactionStatus.Status)
}

// MARK: - FailedToPollError
public struct FailedToPollError: Sendable, LocalizedError, Equatable {
	public let error: Swift.Error
	public var errorDescription: String? {
		"\(Self.self)(error: \(String(describing: error))"
	}
}

// MARK: - FailedToGetTransactionStatus
public struct FailedToGetTransactionStatus: Sendable, LocalizedError, Equatable {
	public let pollAttempts: Int
	public var errorDescription: String? {
		"\(Self.self)(afterPollAttempts: \(String(describing: pollAttempts))"
	}
}

public extension LocalizedError where Self: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}
}

public extension GatewayAPIClient {
	// MARK: -

	// MARK: Submit TX Flow
	func submit(
		notarizedTransaction: Data,
		txID: TXID,
		pollStrategy: PollStrategy = .default
	) async -> Result<SuccessfullySubmittedTransaction, SubmitTXFailure> {
		@Dependency(\.mainQueue) var mainQueue

		// MARK: Submit TX
		let submitTransactionRequest = GatewayAPI.TransactionSubmitRequest(
			notarizedTransaction: notarizedTransaction.hex
		)

		let response: GatewayAPI.TransactionSubmitResponse

		do {
			response = try await submitTransaction(submitTransactionRequest)
		} catch {
			return .failure(.failedToSubmitTX)
		}

		guard !response.duplicate else {
			return .failure(.invalidTXWasDuplicate)
		}

		let transactionIdentifier = GatewayAPI.TransactionLookupIdentifier(
			origin: .intent,
			valueHex: txID.rawValue
		)

		// MARK: Poll Status
		var txStatus: GatewayAPI.TransactionStatus = .init(status: .pending)

		@Sendable func pollTransactionStatus() async throws -> GatewayAPI.TransactionStatus {
			let txStatusRequest = GatewayAPI.TransactionStatusRequest(
				transactionIdentifier: transactionIdentifier
			)
			let txStatusResponse = try await transactionStatus(txStatusRequest)
			return txStatusResponse.transaction.transactionStatus
		}

		var pollCount = 0
		while !txStatus.isComplete {
			defer { pollCount += 1 }
			try? await mainQueue.sleep(for: .seconds(pollStrategy.sleepDuration))

			do {
				txStatus = try await pollTransactionStatus()
			} catch {
				// FIXME: - mainnet: improve hanlding of polling failure, should probably not return failure..
				return .failure(.failedToPollTX(txID: txID, error: .init(error: error)))
			}

			if pollCount >= pollStrategy.maxPollTries {
				return .failure(.failedToGetTransactionStatus(txID: txID, error: .init(pollAttempts: pollCount)))
			}
		}
		guard txStatus.status == .succeeded else {
			return .failure(.invalidTXWasSubmittedButNotSuccessful(txID: txID, status: txStatus.status))
		}

		// MARK: Get TX Details

		let transactionDetailsRequest = GatewayAPI.TransactionDetailsRequest(transactionIdentifier: transactionIdentifier)
		let transactionDetailsResponse: GatewayAPI.TransactionDetailsResponse
		do {
			transactionDetailsResponse = try await transactionDetails(transactionDetailsRequest)
		} catch {
			// Should not consider it a failure if we successfully submitted a transacion but failed to get details for it.
			return .success(.init(txDetails: nil, txID: txID))
		}

		guard transactionDetailsResponse.transaction.transactionStatus.status == .succeeded else {
			// Should not consider it a failure if we successfully submitted a transacion but failed to get details for it.
			return .success(.init(txDetails: nil, txID: txID))
		}

		return .success(.init(txDetails: transactionDetailsResponse, txID: txID))
	}
}

public extension GatewayAPI.TransactionStatus {
	var isComplete: Bool {
		switch status {
		case .succeeded, .failed, .rejected:
			return true
		case .pending:
			return false
		}
	}
}

#if DEBUG
// https://gist.github.com/cprovatas/5c9f51813bc784ef1d7fcbfb89de74fe
extension Data {
	/// NSString gives us a nice sanitized debugDescription
	var prettyPrintedJSONString: NSString? {
		guard
			let object = try? JSONSerialization.jsonObject(with: self, options: []),
			let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
			let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
		else { return nil }

		return prettyPrintedString
	}
}
#endif
