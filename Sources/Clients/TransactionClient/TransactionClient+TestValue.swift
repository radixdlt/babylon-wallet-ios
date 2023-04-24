#if DEBUG
import ClientPrelude

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		lockFeeBySearchingForSuitablePayer: unimplemented("\(Self.self).lockFeeBySearchingForSuitablePayer"),
		lockFeeWithSelectedPayer: unimplemented("\(Self.self).lockFeeWithSelectedPayer"),
		addGuaranteesToManifest: unimplemented("\(Self.self).addGuaranteesToManifest"),
		getTransactionReview: unimplemented("\(Self.self).getTransactionReview")
	)
}
#endif // DEBUG
