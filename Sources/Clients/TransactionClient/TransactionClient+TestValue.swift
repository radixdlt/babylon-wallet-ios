#if DEBUG
import ClientPrelude

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		getTransactionReview: unimplemented("\(Self.self).getTransactionReview"),
		buildTransactionIntent: unimplemented("\(Self.self).buildTransactionIntent"),
		notarizeTransaction: unimplemented("\(Self.self).notarizeTransaction"),
		prepareForSigning: unimplemented("\(Self.self).prepareForSigning"),
		myInvolvedEntities: unimplemented("\(Self.self).myInvolvedEntities")
	)
}
#endif // DEBUG
