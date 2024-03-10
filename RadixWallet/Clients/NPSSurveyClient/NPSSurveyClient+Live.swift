extension DependencyValues {
	public var npsSurveyClient: NPSSurveyClient {
		get { self[NPSSurveyClient.self] }
		set { self[NPSSurveyClient.self] = newValue }
	}
}

// MARK: - NPSSurveyClient + DependencyKey
extension NPSSurveyClient: DependencyKey {
	public static var liveValue: NPSSurveyClient {
		@Dependency(\.userDefaults) var userDefaults

		let shouldAskForFeedbackSubject: AsyncCurrentValueSubject<Bool> = .init(false)

		return .init(
			uploadUserFeedback: uploadUserFeedback,
			incrementTransactionCompleteCounter: {
				let currentCounter = userDefaults.getTransactionsCompletedCounter() ?? 0
				let updatedCounter = currentCounter + 1
				userDefaults.setTransactionsCompletedCounter(updatedCounter)
				if Self.shouldAskUserForFeedback(updatedCounter) {
					shouldAskForFeedbackSubject.send(true)
				}
			},
			shouldAskForUserFeedback: {
				shouldAskForFeedbackSubject.eraseToAnyAsyncSequence()
			}
		)
	}
}

extension NPSSurveyClient {
	private static let feedbackTransactionCounterThreshold = 10
	private static let nextFeedbackIntervalThresholdInMonths = 3

	@Sendable
	static func shouldAskUserForFeedback(_ transactionCounter: Int) -> Bool {
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.date) var date

		if transactionCounter == Self.feedbackTransactionCounterThreshold {
			return true
		} else if transactionCounter > Self.feedbackTransactionCounterThreshold {
			guard let lastSubmittedDate = userDefaults.getDateOfLastSubmittedNPSSurvey() else {
				return false
			}

			let calendar = Calendar.current
			let components = calendar.dateComponents([.month], from: lastSubmittedDate, to: date.now)
			if let monthDiff = components.month {
				return monthDiff >= nextFeedbackIntervalThresholdInMonths
			} else {
				return false
			}
		}
		return false
	}
}

// MARK: - Upload user feedback
extension NPSSurveyClient {
	#if DEBUG
	static let rootURL = "https://dev-wallet-net-promoter-score.radixdlt.com/v1/responses"
	#else
	static let rootURL = "https://wallet-net-promoter-score.radixdlt.com/v1/responses"
	#endif

	private enum QueryItem: String {
		case id
		case formUuid = "form_uuid"
		case nps
		case feedbackReason = "what_do_you_value_most_about_our_service"
	}

	@Sendable
	static func uploadUserFeedback(_ feedback: UserFeedback?) async {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.userDefaults) var userDefaults
		@Dependency(\.date) var date

		/// We consider the feedback sent on user interaction.
		/// No need to actual have a successful upload of the feedback.
		userDefaults.setDateOfLastSubmittedNPSSurvey(date.now)

		let userId = {
			if let userId = userDefaults.getNPSSurveyUserId() {
				return userId
			} else {
				let userId = UUID()
				userDefaults.setNPSSurveyUserId(userId)
				return userId
			}
		}()

		var urlComponents = URLComponents(string: Self.rootURL)!
		urlComponents.queryItems = [.userId(userId), .formUUID] + (feedback.map(\.queryItems) ?? [])

		guard let url = urlComponents.url else {
			return
		}

		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "POST"

		do {
			_ = try await httpClient.executeRequest(urlRequest)
		} catch {
			loggerGlobal.info("Failed to submit nps survey feedback \(error)")
		}
	}
}

private extension URLQueryItem {
	static func userId(_ id: UUID) -> Self {
		.init(name: "id", value: id.uuidString)
	}

	static let formUUID: Self = .init(name: "form_uuid", value: "281622a0-dc6b-11ee-8fd1-23c96056fbd2")

	static func npsScore(_ score: Int) -> Self {
		.init(name: "nps", value: "\(score)")
	}

	static func npsFeedbackReason(_ reason: String) -> Self {
		.init(name: "what_do_you_value_most_about_our_service", value: reason)
	}
}

extension NPSSurveyClient.UserFeedback {
	var queryItems: [URLQueryItem] {
		var queryItems: [URLQueryItem] = []
		queryItems.append(.npsScore(npsScore))
		if let reason {
			queryItems.append(.npsFeedbackReason(reason))
		}
		return queryItems
	}
}
