// MARK: - ResourcesVisibilityClient
/// Controls the visibility of resources in the Wallet
public struct ResourcesVisibilityClient: Sendable {
	public var hide: Hide
	public var getHidden: GetHidden
	public var hiddenValues: HiddenValues
}

extension ResourcesVisibilityClient {
	public typealias Hide = @Sendable (ResourceIdentifier, Bool) async throws -> Void
	public typealias GetHidden = @Sendable () async throws -> [ResourceIdentifier]
	public typealias HiddenValues = @Sendable () async -> AnyAsyncSequence<[ResourceIdentifier]>
}

extension ResourcesVisibilityClient {
	public func hide(_ resource: ResourceIdentifier) async throws {
		try await hide(resource, true)
	}

	public func unhide(_ resource: ResourceIdentifier) async throws {
		try await hide(resource, false)
	}

	public func isHidden(_ resource: ResourceIdentifier) async throws -> Bool {
		try await getHidden().contains(resource)
	}
}
