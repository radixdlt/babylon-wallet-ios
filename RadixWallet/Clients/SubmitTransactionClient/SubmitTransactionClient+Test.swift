
extension DependencyValues {
	public var submitTXClient: SubmitTransactionClient {
		get { self[SubmitTransactionClient.self] }
		set { self[SubmitTransactionClient.self] = newValue }
	}
}

// MARK: - SubmitTransactionClient + TestDependencyKey
extension SubmitTransactionClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		submitTransaction: unimplemented("\(Self.self).submitTransaction"),
		hasTXBeenCommittedSuccessfully: unimplemented("\(Self.self).hasTXBeenCommittedSuccessfully")
	)

	public static let noop = Self(
		submitTransaction: { _ in
			throw NoopError()
		},
		hasTXBeenCommittedSuccessfully: { _ in }
	)
}
