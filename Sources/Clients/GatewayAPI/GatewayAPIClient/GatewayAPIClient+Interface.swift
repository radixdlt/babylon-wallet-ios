import Common
import CryptoKit
import Dependencies
import EngineToolkit
import Foundation
import Profile

public typealias ResourceIdentifier = String

// MARK: - GatewayAPIClient
public struct GatewayAPIClient: Sendable, DependencyKey {
	// MARK: Request
	public var getGatewayInfo: GetGatewayInfo
	public var getNetworkName: GetNetworkName
	public var getEpoch: GetEpoch
	public var accountResourcesByAddress: GetAccountResourcesByAddress
	public var resourcesOverview: GetResourcesOverview
	public var resourceDetailsByResourceIdentifier: GetResourceDetailsByResourceIdentifier
	public var submitTransaction: SubmitTransaction
	public var transactionStatus: GetTransactionStatus
}

public extension GatewayAPIClient {
	typealias GetGatewayInfo = @Sendable () async throws -> GatewayAPI.TransactionConstructionResponse
	typealias GetEpoch = @Sendable () async throws -> Epoch
	typealias GetNetworkName = @Sendable (URL) async throws -> Network.Name

	typealias GetAccountResourcesByAddress = @Sendable (AccountAddress) async throws -> GatewayAPI.EntityResourcesResponse

	typealias GetResourcesOverview = @Sendable (GatewayAPI.EntityOverviewRequest) async throws -> GatewayAPI.EntityOverviewResponse

	typealias GetResourceDetailsByResourceIdentifier = @Sendable (ResourceIdentifier) async throws -> GatewayAPI.EntityDetailsResponse

	typealias SubmitTransaction = @Sendable (GatewayAPI.TransactionSubmitRequest) async throws -> GatewayAPI.TransactionSubmitResponse

	typealias GetTransactionStatus = @Sendable (GatewayAPI.TransactionStatusRequest) async throws -> GatewayAPI.TransactionStatusResponse
}
