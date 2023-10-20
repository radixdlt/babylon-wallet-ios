import LocalAuthentication

// MARK: - LocalAuthenticationClient + DependencyKey
extension LocalAuthenticationClient: DependencyKey {
	public static let liveValue: Self = .init(
		queryConfig: {
			try LAContext().queryLocalAuthenticationConfig()
		}
	)
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
		let canEvaluate = self.canEvaluatePolicy(policy, error: &error)

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

		switch result {
		case let .success(canEvaluate_):
			return canEvaluate_
		case let .failure(error):
			throw error
		}
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
