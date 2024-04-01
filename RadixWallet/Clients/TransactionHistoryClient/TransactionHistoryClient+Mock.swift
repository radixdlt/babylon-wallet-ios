// MARK: - TransactionHistoryClient + TestDependencyKey
extension TransactionHistoryClient: TestDependencyKey {
	public static let previewValue = Self.mock()

	public static let testValue = Self(
		getFirstTransactionDate: unimplemented("\(Self.self).getFirstTransactionDate"),
		getTransactionHistory: unimplemented("\(Self.self).getTransactionHistory")
	)

	// TODO: convert to noop, don't use in tests.
	private static func mock() -> Self {
		.init(
			getFirstTransactionDate: unimplemented("\(self).getFirstTransactionDate"),
			getTransactionHistory: unimplemented("\(self).getTransactionHistory")
		)
	}
}

extension DependencyValues {
	public var transactionHistoryClient: TransactionHistoryClient {
		get { self[TransactionHistoryClient.self] }
		set { self[TransactionHistoryClient.self] = newValue }
	}
}
