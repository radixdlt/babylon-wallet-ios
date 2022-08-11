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
		localAuthenticationContext laContext: LAContext = .init()
	) -> Self {
		.init(
			queryConfig: {
				try await laContext.queryLocalAuthenticationConfig()
			}
		)
	}
}

public extension LocalAuthenticationClient {
	enum Error: Swift.Error, Equatable {
		case contextDeinitialized
		case queryCancelled
		case evaluationError(LAError)
		case evaluationFailedWithOtherError(reason: String)
	}
}

private extension LAContext {
	typealias Error = LocalAuthenticationClient.Error

	func evaluateIfPasscodeIsSetUp() async throws -> Bool {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Bool, Swift.Error>) in
			guard let self = self else {
				continuation.resume(throwing: Error.contextDeinitialized)
				return
			}
			var error: NSError?
			let canEvaluate = self.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

			if let evaluationError = error {
				if let laError = evaluationError as? LAError {
					switch laError.code {
					case .appCancel, .userCancel:
						continuation.resume(throwing: Error.queryCancelled)
					case .passcodeNotSet:
						continuation.resume(returning: false)
					case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
						break // irrelevant for passcode
					default:
						debugPrint("Unhandled error case: \(laError)")
						continuation.resume(throwing: Error.evaluationError(laError))
						return
					}
				} else {
					let reason = String(describing: error)
					debugPrint("Bad error type, expected `LAError`, error was: \(reason)")
					continuation.resume(throwing: Error.evaluationFailedWithOtherError(reason: reason))
					return
				}
			}
			print("canEvaluate: \(canEvaluate)")
			continuation.resume(returning: canEvaluate)
		}
	}

	func evaluateIfBiometricsIsSetUp() async throws -> Bool {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Bool, Swift.Error>) in
			guard let self = self else {
				continuation.resume(throwing: Error.contextDeinitialized)
				return
			}
			var error: NSError?
			let canEvaluate = self.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

			if let evaluationError = error {
				if let laError = evaluationError as? LAError {
					switch laError.code {
					case .appCancel, .userCancel:
						continuation.resume(throwing: Error.queryCancelled)
					case .passcodeNotSet:
						fatalError("BAD STATE")
					//                        continuation.resume(returning: false)
					case .biometryNotEnrolled, .biometryLockout, .biometryNotAvailable:
						continuation.resume(returning: false)
					default:
						debugPrint("Unhandled error case: \(laError)")
						continuation.resume(throwing: Error.evaluationError(laError))
						return
					}
				} else {
					let reason = String(describing: error)
					debugPrint("Bad error type, expected `LAError`, error was: \(reason)")
					continuation.resume(throwing: Error.evaluationFailedWithOtherError(reason: reason))
					return
				}
			}
			print("canEvaluate: \(canEvaluate)")
			continuation.resume(returning: canEvaluate)
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
