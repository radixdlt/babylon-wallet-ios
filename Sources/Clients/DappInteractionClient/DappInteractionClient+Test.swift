import ClientPrelude

extension DependencyValues {
	public var dappInteractionClient: DappInteractionClient {
		get { self[DappInteractionClient.self] }
		set { self[DappInteractionClient.self] = newValue }
	}
}

// MARK: - DappInteractionClient + TestDependencyKey
extension DappInteractionClient: TestDependencyKey {
	public static let noop = Self(
		requests: AsyncLazySequence([]).eraseToAnyAsyncSequence(),
		addWalletRequest: { _ in },
		sendResponse: { _ in }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		requests: unimplemented("\(Self.self).requests"),
		addWalletRequest: unimplemented("\(Self.self).addWalletRequest"),
		sendResponse: unimplemented("\(Self.self).sendResponse")
	)
}
