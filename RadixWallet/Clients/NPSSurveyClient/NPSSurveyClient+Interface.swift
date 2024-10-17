// MARK: - NPSSurveyClient
struct NPSSurveyClient: Sendable {
	var uploadUserFeedback: UploadUserFeedback
	var incrementTransactionCompleteCounter: IncrementTransactionCompleteCounter
	var shouldAskForUserFeedback: ShouldAskForUserFeedback
}

extension NPSSurveyClient {
	struct UserFeedback: Equatable, Sendable {
		let npsScore: Int
		let reason: String?
	}

	typealias UploadUserFeedback = @Sendable (UserFeedback?) async -> Void
	typealias IncrementTransactionCompleteCounter = @Sendable () -> Void
	typealias ShouldAskForUserFeedback = @Sendable () async -> AnyAsyncSequence<Bool>
}
