import Foundation

// MARK: - RequestMethodWalletResponse
public struct RequestMethodWalletResponse: Encodable {
	public let method: RequestMethod
	public let requestId: String
	public let payload: [Payload]

	public init(
		method: RequestMethod,
		requestId: String,
		payload: [Payload]
	) {
		self.method = method
		self.requestId = requestId
		self.payload = payload
	}
}

// MARK: RequestMethodWalletResponse.Payload
public extension RequestMethodWalletResponse {
	enum Payload: Encodable {
		case accountAddresses(AccountAddressesRequestMethodWalletResponse)
	}
}

// MARK: RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse
public extension RequestMethodWalletResponse {
	struct AccountAddressesRequestMethodWalletResponse: Encodable {
		let requestType: RequestType
		let accountAddresses: [AccountAddress]
	}
}

// MARK: - RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse.AccountAddress
extension RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse {
	struct AccountAddress: Encodable {
		let address: String
		let label: String
	}
}
