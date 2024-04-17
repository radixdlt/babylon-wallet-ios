// MARK: - NPSSurveyClient
public struct NPSSurveyClient: Sendable {
	public var uploadUserFeedback: UploadUserFeedback
	public var incrementTransactionCompleteCounter: IncrementTransactionCompleteCounter
	public var shouldAskForUserFeedback: ShouldAskForUserFeedback
}

extension NPSSurveyClient {
	public struct UserFeedback: Equatable, Sendable {
		public let npsScore: Int
		public let reason: String?
	}

	public typealias UploadUserFeedback = (UserFeedback?) async -> Void
	public typealias IncrementTransactionCompleteCounter = () -> Void
	public typealias ShouldAskForUserFeedback = () -> AnyAsyncSequence<Bool>
}
