import Sargon

// MARK: - SubmitTransactionClient + DependencyKey
extension SubmitTransactionClient: DependencyKey {
	typealias Value = SubmitTransactionClient

	static let liveValue: Self = {
		let submitTransaction: SubmitTransaction = { notarizedTransaction in
			try await SargonOS.shared.submitTransaction(notarizedTransaction: notarizedTransaction)
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
