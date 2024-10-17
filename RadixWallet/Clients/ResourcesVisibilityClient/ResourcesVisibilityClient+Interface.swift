// MARK: - ResourcesVisibilityClient
/// Controls the visibility of resources in the Wallet
struct ResourcesVisibilityClient: Sendable {
	var hide: Hide
	var getHidden: GetHidden
	var hiddenValues: HiddenValues
}

extension ResourcesVisibilityClient {
	typealias Hide = @Sendable (ResourceIdentifier, Bool) async throws -> Void
	typealias GetHidden = @Sendable () async throws -> [ResourceIdentifier]
	typealias HiddenValues = @Sendable () async -> AnyAsyncSequence<[ResourceIdentifier]>
}

extension ResourcesVisibilityClient {
	func hide(_ resource: ResourceIdentifier) async throws {
		try await hide(resource, true)
	}

	func unhide(_ resource: ResourceIdentifier) async throws {
		try await hide(resource, false)
	}

	func isHidden(_ resource: ResourceIdentifier) async throws -> Bool {
		try await getHidden().contains(resource)
	}
}
