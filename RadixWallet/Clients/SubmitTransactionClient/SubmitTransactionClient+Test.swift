
extension DependencyValues {
	var submitTXClient: SubmitTransactionClient {
		get { self[SubmitTransactionClient.self] }
		set { self[SubmitTransactionClient.self] = newValue }
	}
}

// MARK: - SubmitTransactionClient + TestDependencyKey
extension SubmitTransactionClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		submitTransaction: unimplemented("\(Self.self).submitTransaction"),
		pollTransactionStatus: unimplemented("\(Self.self).pollTransactionStatus")
	)

	static let noop = Self(
		submitTransaction: { _ in
			throw NoopError()
		},
		pollTransactionStatus: { _ in
			throw NoopError()
		}
	)
}
