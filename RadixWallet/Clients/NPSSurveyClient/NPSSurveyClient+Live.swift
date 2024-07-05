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
			uploadUserFeedback: { feedback in
				await uploadUserFeedback(feedback)
				shouldAskForFeedbackSubject.send(false)
			},
			incrementTransactionCompleteCounter: {
				let currentCounter = userDefaults.getTransactionsCompletedCounter() ?? 0
				let lastDate = userDefaults.getDateOfLastSubmittedNPSSurvey()
				let updatedCounter = currentCounter + 1
				userDefaults.setTransactionsCompletedCounter(updatedCounter)
				if Self.shouldAskUserForFeedback(updatedCounter, dateOfLastSubmittedNPSSurvey: lastDate) {
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
	static func shouldAskUserForFeedback(_ transactionCounter: Int, dateOfLastSubmittedNPSSurvey: Date?) -> Bool {
		@Dependency(\.date) var date

		if transactionCounter == Self.feedbackTransactionCounterThreshold {
			return true
		} else if transactionCounter > Self.feedbackTransactionCounterThreshold {
			guard let lastSubmittedDate = dateOfLastSubmittedNPSSurvey else {
				// No submit date saved?
				// Can happen if user did close the app while the original NPS survey was shown.
				// And since the next NPS survey check will happen only after user did perform
				// yet another transaction, the execution will reach this guard branch.
				// Therefore, it is considered that user did not yet submit an NPS survey, so ask the user
				// to complete the it.
				return true
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
	static let formUUID = "281622a0-dc6b-11ee-8fd1-23c96056fbd2"
	#else
	static let rootURL = "https://wallet-net-promoter-score.radixdlt.com/v1/responses"
	static let formUUID = "3432b6e0-dfad-11ee-a53c-95167f067d9c"
	#endif

	enum BodyParam: String {
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
		/// No need to actually have a successful upload of the feedback.
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

		let urlComponents = URLComponents(string: Self.rootURL)!

		guard let url = urlComponents.url else {
			return
		}

		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "POST"
		urlRequest.allHTTPHeaderFields = [
			"accept": "application/json",
			"Content-Type": "application/json",
		]

		var feedbackParams: [String: Any] = [
			BodyParam.id.rawValue: userId.uuidString,
			BodyParam.formUuid.rawValue: formUUID,
		]
		if let feedback {
			feedbackParams[BodyParam.nps.rawValue] = feedback.npsScore
		}
		if let reason = feedback?.reason {
			feedbackParams[BodyParam.feedbackReason.rawValue] = reason
		}
		urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: feedbackParams)

		do {
			_ = try await httpClient.executeRequest(urlRequest, [.ok, .accepted])
		} catch {
			loggerGlobal.info("Failed to submit nps survey feedback \(error)")
		}
	}
}
