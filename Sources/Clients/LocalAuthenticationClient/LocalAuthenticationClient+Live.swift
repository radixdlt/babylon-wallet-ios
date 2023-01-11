import LocalAuthentication
import Prelude

// MARK: - LocalAuthenticationClient + DependencyKey
extension LocalAuthenticationClient: DependencyKey {
	public static let liveValue: Self = .init(
		queryConfig: {
			try await LAContext().queryLocalAuthenticationConfig()
		}
	)
}

// MARK: - LocalAuthenticationClient.Error
public extension LocalAuthenticationClient {
	enum Error: Swift.Error, Equatable {
		case contextDeinitialized
		case queryCancelled
		case evaluationError(LAError)
		case evaluationFailedWithOtherError(reason: String)
		case evaluateBioDiscrepancyPasscodeNotSetButExpectedToBe
	}
}

private extension LAContext {
	typealias Error = LocalAuthenticationClient.Error

	func canEvaluate(
		policy: LAPolicy,
		errorHandling: (LAError) -> Result<Bool, Error>?
	) async throws -> Bool {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Bool, Swift.Error>) in
			guard let self = self else {
				continuation.resume(throwing: Error.contextDeinitialized)
				return
			}
			var error: NSError?
			let canEvaluate = self.canEvaluatePolicy(policy, error: &error)

			guard let evaluationError = error else {
				continuation.resume(returning: canEvaluate)
				return
			}

			guard let laError = evaluationError as? LAError else {
				let reason = String(describing: error)
				continuation.resume(throwing: Error.evaluationFailedWithOtherError(reason: reason))
				return
			}

			guard let result = errorHandling(laError) else {
				continuation.resume(returning: canEvaluate)
				return
			}

			switch result {
			case let .success(canEvaluate_):
				continuation.resume(returning: canEvaluate_)
				return
			case let .failure(error):
				continuation.resume(throwing: error)
				return
			}
		}
	}

	func evaluateIfPasscodeIsSetUp() async throws -> Bool {
		try await canEvaluate(policy: .deviceOwnerAuthentication) { laError in
			switch laError.code {
			case .appCancel, .userCancel:
				return .failure(.queryCancelled)
			case .passcodeNotSet:
				return .success(false)
			case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
				return nil // irrelevant for passcode
			default:
				return .failure(.evaluationError(laError))
			}
		}
	}

	func evaluateIfBiometricsIsSetUp() async throws -> Bool {
		try await canEvaluate(policy: .deviceOwnerAuthenticationWithBiometrics) { laError in
			switch laError.code {
			case .appCancel, .userCancel:
				return .failure(.queryCancelled)
			case .passcodeNotSet:
				return .failure(.evaluateBioDiscrepancyPasscodeNotSetButExpectedToBe)
			case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
				return .success(false)
			default:
				return .failure(.evaluationError(laError))
			}
		}
	}

	// Returns `nil` if user presses "cancel" button
	func queryLocalAuthenticationConfig() async throws -> LocalAuthenticationConfig {
		let passcodeSupportedResult = try await evaluateIfPasscodeIsSetUp()

		guard passcodeSupportedResult else {
			return .neitherBiometricsNorPasscodeSetUp
		}

		let biometricsSupportedResult = try await evaluateIfBiometricsIsSetUp()

		guard biometricsSupportedResult else {
			return .passcodeSetUpButNotBiometrics
		}

		return .biometricsAndPasscodeSetUp
	}
}
