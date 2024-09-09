import LocalAuthentication

// MARK: - LocalAuthenticationClient + DependencyKey
extension LocalAuthenticationClient: DependencyKey {
	public static let liveValue: Self = {
		let authenticatedSuccessfully = AsyncPassthroughSubject<Void>()

		return .init(
			queryConfig: {
				try LAContext().queryLocalAuthenticationConfig()
			},
			authenticateWithBiometrics: {
				try await LAContext().authenticateWithBiometrics()
			},
			setAuthenticatedSuccessfully: { authenticatedSuccessfully.send(()) },
			authenticatedSuccessfully: { authenticatedSuccessfully.eraseToAnyAsyncSequence() }
		)
	}()
}

// MARK: - LocalAuthenticationClient.Error
extension LocalAuthenticationClient {
	public enum Error: Swift.Error, Equatable {
		case contextDeinitialized
		case queryCancelled
		case evaluationError(LAError)
		case evaluationFailedWithOtherError(reason: String)
		case evaluateBioDiscrepancyPasscodeNotSetButExpectedToBe
	}
}

extension LAContext {
	fileprivate typealias Error = LocalAuthenticationClient.Error

	private func canEvaluate(
		policy: LAPolicy,
		errorHandling: (LAError) -> Result<Bool, Error>?
	) throws -> Bool {
		var error: NSError?
		let canEvaluate = canEvaluatePolicy(policy, error: &error)

		guard let evaluationError = error else {
			return canEvaluate
		}

		guard let laError = evaluationError as? LAError else {
			let reason = String(describing: error)
			throw Error.evaluationFailedWithOtherError(reason: reason)
		}

		guard let result = errorHandling(laError) else {
			return canEvaluate
		}

		return try result.get()
	}

	private func evaluateIfPasscodeIsSetUp() throws -> Bool {
		try canEvaluate(policy: .deviceOwnerAuthentication) { laError in
			switch laError.code {
			case .appCancel, .userCancel:
				.failure(.queryCancelled)
			case .passcodeNotSet:
				.success(false)
			case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
				nil // irrelevant for passcode
			default:
				.failure(.evaluationError(laError))
			}
		}
	}

	private func evaluateIfBiometricsIsSetUp() throws -> Bool {
		try canEvaluate(policy: .deviceOwnerAuthenticationWithBiometrics) { laError in
			switch laError.code {
			case .appCancel, .userCancel:
				.failure(.queryCancelled)
			case .passcodeNotSet:
				.failure(.evaluateBioDiscrepancyPasscodeNotSetButExpectedToBe)
			case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
				.success(false)
			default:
				.failure(.evaluationError(laError))
			}
		}
	}

	fileprivate func authenticateWithBiometrics() async throws -> Bool {
		try await withCheckedThrowingContinuation { continuation in
			evaluatePolicy(
				.deviceOwnerAuthenticationWithBiometrics,
				localizedReason: L10n.Biometrics.Prompt.title
			) { success, error in
				if let error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume(returning: success)
				}
			}
		}
	}

	// Returns `nil` if user presses "cancel" button
	fileprivate func queryLocalAuthenticationConfig() throws -> LocalAuthenticationConfig {
		let passcodeSupportedResult = try evaluateIfPasscodeIsSetUp()

		guard passcodeSupportedResult else {
			return .neitherBiometricsNorPasscodeSetUp
		}

		let biometricsSupportedResult = try evaluateIfBiometricsIsSetUp()

		guard biometricsSupportedResult else {
			return .passcodeSetUpButNotBiometrics
		}

		return .biometricsAndPasscodeSetUp
	}
}
