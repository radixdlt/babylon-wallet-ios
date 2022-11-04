import EngineToolkit
import Foundation
import Profile

// MARK: - RequestMethodWalletResponse
public struct RequestMethodWalletResponse: Sendable, Hashable, Encodable {
	public typealias RequestID = RequestMethodWalletRequest.RequestID
	public let method: RequestMethod
	public let requestId: RequestID
	public let payload: [Payload]

	public init(
		method: RequestMethod,
		requestId: RequestID,
		payload: [Payload]
	) {
		self.method = method
		self.requestId = requestId
		self.payload = payload
	}
}

// MARK: RequestMethodWalletResponse.Payload
public extension RequestMethodWalletResponse {
	enum Payload: Sendable, Hashable, Encodable {
		case accountAddresses(AccountAddressesRequestMethodWalletResponse)
		case signTXRequest(SignTXResponseToDapp)
	}
}

public extension RequestMethodWalletResponse.Payload {
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case let .accountAddresses(payload):
			try container.encode(payload)
		case let .signTXRequest(payload):
			try container.encode(payload)
		}
	}
}

// MARK: - RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse
public extension RequestMethodWalletResponse {
	struct AccountAddressesRequestMethodWalletResponse: Sendable, Hashable, Encodable {
		public let requestType: RequestType
		public let addresses: [AccountAddress]

		public init(
			addresses: [AccountAddress]
		) {
			requestType = .accountAddresses
			self.addresses = addresses
		}
	}
}

// MARK: - RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse.AccountAddress
public extension RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse {
	struct AccountAddress: Sendable, Hashable, Encodable {
		public let address: String
		public let label: String

		public init(address: String, label: String) {
			self.address = address
			self.label = label
		}
	}
}

// MARK: - RequestMethodWalletResponse.SignTXResponseToDapp
public extension RequestMethodWalletResponse {
	struct SignTXResponseToDapp: Sendable, Hashable, Encodable {
		public let requestType: RequestType

		/// TransactionIntent hex string
		public let transactionIntentHash: TransactionIntent.TXID

		public init(
			transactionIntentHash: TransactionIntent.TXID
		) {
			requestType = .sendTransaction
			self.transactionIntentHash = transactionIntentHash
		}
	}
}
