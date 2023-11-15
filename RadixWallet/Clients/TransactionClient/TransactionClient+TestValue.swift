#if DEBUG

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		getTransactionReview: unimplemented("\(Self.self).getTransactionReview"),
		buildTransactionIntent: unimplemented("\(Self.self).buildTransactionIntent"),
		notarizeTransaction: unimplemented("\(Self.self).notarizeTransaction"),
		myInvolvedEntities: unimplemented("\(Self.self).myInvolvedEntities"),
		determineFeePayer: unimplemented("\(Self.self).determineFeePayer"),
		getFeePayerCandidates: unimplemented("\(Self.self).getFeePayerCandidates")
	)
}
#endif // DEBUG
