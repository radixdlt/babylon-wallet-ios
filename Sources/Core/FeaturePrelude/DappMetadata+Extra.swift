#if canImport(GatewayAPI)
import GatewayAPI
import SharedModels

public extension DappMetadata {
	init(
		for dappDefinitionAddress: DappDefinitionAddress
	) async throws {
		@Dependency(\.gatewayAPIClient) var gatewayAPI
		let metadata = try await gatewayAPI.accountMetadataByAddress(dappDefinitionAddress).metadata
		self.init(
			name: metadata.items.first(where: { $0.key == "name" })?.value ?? "",
			description: metadata.items.first(where: { $0.key == "description" })?.value ?? ""
		)
	}
}
#endif
