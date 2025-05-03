
extension DependencyValues {
	var dappInteractionClient: DappInteractionClient {
		get { self[DappInteractionClient.self] }
		set { self[DappInteractionClient.self] = newValue }
	}
}

// MARK: - DappInteractionClient + TestDependencyKey
extension DappInteractionClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		interactions: unimplemented("\(Self.self).requests", placeholder: noop.interactions),
		addWalletInteraction: unimplemented("\(Self.self).addWalletRequest", placeholder: noop.addWalletInteraction),
		completeInteraction: unimplemented("\(Self.self).sendResponse")
	)

	static let noop = Self(
		interactions: AsyncLazySequence([]).eraseToAnyAsyncSequence(),
		addWalletInteraction: { _, _ in .none },
		completeInteraction: { _ in }
	)
}
