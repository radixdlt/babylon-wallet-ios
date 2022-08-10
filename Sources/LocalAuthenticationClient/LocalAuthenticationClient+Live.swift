//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-08-10.
//

import Foundation
import LocalAuthentication

public extension LocalAuthenticationClient {
	static func live(
		localAuthenticationContext: LAContext = .init()
	) -> Self {
		.init(
			queryConfig: {
				try await localAuthenticationContext.queryLocalAuthenticationConfig()
			}
		)
	}
}

private extension LAContext {
	func canEvaluate(
		policy: LAPolicy
	) async -> Bool? {
		await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Bool?, Never>) in
			guard let self = self else {
				fatalError("What to do")
			}
			var error: NSError?
			let canEvaluate = self.canEvaluatePolicy(policy, error: &error)
			if let evaluationError = error {
				if let laError = evaluationError as? LAError {
					switch laError.code {
					case .appCancel, .userCancel:
						continuation.resume(returning: nil)
					case .passcodeNotSet:
						continuation.resume(returning: false)
					case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
						continuation.resume(returning: false)
					default:
						fatalError("Unhandled error case: \(laError)")
					}
				} else {
					fatalError("Bad error type")
				}
			} else {
				continuation.resume(returning: canEvaluate)
			}
		}
	}

	// Returns `nil` if user presses "cancel" button
	func queryLocalAuthenticationConfig() async throws -> LocalAuthenticationConfig? {
		guard let passcodeSupportedResult = await canEvaluate(policy: .deviceOwnerAuthentication) else {
			return nil
		}
		guard passcodeSupportedResult else {
			return .neitherBiometricsNorPasscodeSetUp
		}

		guard let biometricsSupportedResult = await canEvaluate(policy: .deviceOwnerAuthenticationWithBiometrics) else {
			return .passcodeSetUpButBiometricsIsUnknown
		}
		guard biometricsSupportedResult else {
			return .passcodeSetUpButNotBiometrics
		}
		return .biometricsAndPasscodeSetUp
	}
}
