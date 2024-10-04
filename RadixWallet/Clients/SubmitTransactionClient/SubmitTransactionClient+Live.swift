import Sargon

// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	public typealias Value = SubmitTransactionClient

	public static let liveValue: Self = {
		let submitTransaction: SubmitTransaction = { compiledNotarizedIntent in
			try await SargonOS.shared.submitCompiledTransaction(compiledNotarizedIntent: compiledNotarizedIntent)
		}

		let pollTransactionStatus: PollTransactionStatus = { intentHash in
			try await SargonOS.shared.pollTransactionStatus(intentHash: intentHash)
		}

		return Self(
			submitTransaction: submitTransaction,
			pollTransactionStatus: pollTransactionStatus
		)
	}()
}
