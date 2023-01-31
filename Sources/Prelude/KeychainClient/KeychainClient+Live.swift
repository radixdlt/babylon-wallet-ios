import Dependencies
import Foundation
import KeychainAccess

// MARK: - Keychain + Sendable
extension Keychain: @unchecked Sendable {}

// MARK: - KeychainClient + DependencyKey
extension KeychainClient: DependencyKey {
	public static let liveValue: Self = {
		let keychain = Keychain(service: "Radix Wallet")
			.label("Radix Wallet")
			.synchronizable(false)
			.accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .biometryCurrentSet)

		/// Do not run in the main thread if there is a possibility that the item you are trying to add already exists, and protected. Because updating protected items requires authentication.
		/// https://github.com/kishikawakatsumi/KeychainAccess#closed_lock_with_key-updating-a-touch-id-face-id-protected-item
		let updateDataForKey: UpdateDataForKey = { @Sendable data, key, maybeProtection, maybeAuthenticationPrompt in
			guard let protection = maybeProtection else {
				if let authenticationPrompt = maybeAuthenticationPrompt {
					return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
						Task {
							do {
								try keychain
									.authenticationPrompt(authenticationPrompt)
									.set(data, key: key)
								continuation.resume(returning: ())
							} catch {
								continuation.resume(throwing: error)
							}
						}
					}
				} else {
					return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
						Task {
							do {
								try keychain
									.set(data, key: key)
								continuation.resume(returning: ())
							} catch {
								continuation.resume(throwing: error)
							}
						}
					}
				}
			}

			guard let authenticationPrompt = maybeAuthenticationPrompt else {
				return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
					Task {
						do {
							try keychain
								.accessibility(
									protection.accessibility,
									authenticationPolicy: protection.authenticationPolicy
								)
								.set(data, key: key)
							continuation.resume(returning: ())
						} catch {
							continuation.resume(throwing: error)
						}
					}
				}
			}
			return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
				Task {
					do {
						try keychain
							.accessibility(
								protection.accessibility,
								authenticationPolicy: protection.authenticationPolicy
							)
							.authenticationPrompt(authenticationPrompt)
							.set(data, key: key)
						continuation.resume(returning: ())
					} catch {
						continuation.resume(throwing: error)
					}
				}
			}
		}

		return Self(
			dataForKey: { @Sendable key, authenticationPrompt in
				/// Do not run in the main thread if there is a possibility that the item you are trying to add already exists, and protected. Because updating protected items requires authentication.
				/// https://github.com/kishikawakatsumi/KeychainAccess#closed_lock_with_key-updating-a-touch-id-face-id-protected-item
				try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
					Task {
						do {
							let value = try keychain
								.authenticationPrompt(authenticationPrompt)
								.getData(key)
							continuation.resume(returning: value)
						} catch {
							continuation.resume(throwing: error)
						}
					}
				}
			},
			removeDataForKey: { @Sendable key in
				/// Do not run in the main thread if there is a possibility that the item you are trying to add already exists, and protected. Because updating protected items requires authentication.
				/// https://github.com/kishikawakatsumi/KeychainAccess#closed_lock_with_key-updating-a-touch-id-face-id-protected-item
				try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
					Task {
						do {
							try keychain.remove(key)
							continuation.resume(returning: ())
						} catch {
							continuation.resume(throwing: error)
						}
					}
				}
			},
			setDataForKey: { @Sendable in try await updateDataForKey($0, $1, $2, nil) },
			updateDataForKey: updateDataForKey
		)
	}()
}
