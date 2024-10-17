// MARK: - Asset
protocol Asset: Sendable, Hashable, Identifiable {
	/// The Scrypto Component address of asset.
	var resourceAddress: ResourceAddress { get }
}

extension Asset {
	var id: ResourceAddress { resourceAddress }
}
