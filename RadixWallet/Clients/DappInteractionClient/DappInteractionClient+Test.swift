
extension DependencyValues {
	public var dappInteractionClient: DappInteractionClient {
		get { self[DappInteractionClient.self] }
		set { self[DappInteractionClient.self] = newValue }
	}
}

// MARK: - DappInteractionClient + TestDependencyKey
extension DappInteractionClient: TestDependencyKey {
	public static let noop = Self(
		interactions: AsyncLazySequence([]).eraseToAnyAsyncSequence(),
		addWalletInteraction: { _, _ in .none },
		completeInteraction: { _ in }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		interactions: unimplemented("\(Self.self).requests"),
		addWalletInteraction: unimplemented("\(Self.self).addWalletRequest"),
		completeInteraction: unimplemented("\(Self.self).sendResponse")
	)
}
