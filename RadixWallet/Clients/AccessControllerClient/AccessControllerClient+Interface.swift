import Sargon

// MARK: - AccessControllerClient
struct AccessControllerClient: Sendable {
	/// Get all access controller state details
	var getAllAccessControllerStateDetails: GetAllAccessControllerStateDetails

	var getAccessControllerStateDetails: GetAccessControllerStateDetails

	/// Stream of all access controller state details, periodically refreshed
	var accessControllerStateDetailsUpdates: AccessControllerStateDetailsUpdates

	/// Stream for a specific access controller address
	var accessControllerUpdates: AccessControllerUpdates

	/// Force an immediate refresh of access controller state details
	var forceRefresh: ForceRefresh
}

extension AccessControllerClient {
	typealias GetAllAccessControllerStateDetails = @Sendable () async throws -> [AccessControllerStateDetails]
	typealias GetAccessControllerStateDetails = @Sendable (AccessControllerAddress) async throws -> AccessControllerStateDetails
	typealias AccessControllerStateDetailsUpdates = @Sendable () async -> AnyAsyncSequence<[AccessControllerStateDetails]>
	typealias AccessControllerUpdates = @Sendable (AccessControllerAddress) async -> AnyAsyncSequence<AccessControllerStateDetails?>
	typealias ForceRefresh = @Sendable () async -> Void
}
