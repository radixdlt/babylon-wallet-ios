import CacheClient
import EngineKit
import Foundation
import GatewayAPI
import Prelude
import SharedModels

// MARK: - OnLedgerEntitiesClient
public struct OnLedgerEntitiesClient: Sendable {
	public let getResources: GetResources
	public let getResource: GetResource
}

// MARK: - OnLedgerEntitiesClient.GetResources
extension OnLedgerEntitiesClient {
	public typealias GetResources = @Sendable ([ResourceAddress]) async throws -> [OnLedgerEntity.Resource]
	public typealias GetResource = @Sendable (ResourceAddress) async throws -> OnLedgerEntity.Resource
}
