import Dependencies
import Foundation
import KeychainAccess

public extension DependencyValues {
	var keychainClient: KeychainClient {
		get { self[KeychainClient.self] }
		set { self[KeychainClient.self] = newValue }
	}
}

public extension KeychainClient {
	static var liveValue: Self = live()

	static func live(
		accessibility: Accessibility = .whenPasscodeSetThisDeviceOnly,
		authenticationPolicy: AuthenticationPolicy = .biometryCurrentSet,
		service: String? = "Radix Wallet",
		accessGroup: String? = nil,
		label: String? = "Radix Wallet"
	) -> Self {
		let base: Keychain = {
			switch (service, accessGroup) {
			case (.none, .none):
				return Keychain()
			case let (.some(service), .none):
				return Keychain(service: service)
			case let (.some(service), .some(accessGroup)):
				return Keychain(service: service, accessGroup: accessGroup)
			case let (.none, .some(accessGroup)):
				return Keychain(accessGroup: accessGroup)
			}
		}()

		let keychain = label.map {
			base.label($0)
		} ?? base

		let wrapped = keychain
			.synchronizable(false)
			.accessibility(accessibility, authenticationPolicy: authenticationPolicy)

		/// Do not run in the main thread if there is a possibility that the item you are trying to add already exists, and protected. Because updating protected items requires authentication.
		/// https://github.com/kishikawakatsumi/KeychainAccess#closed_lock_with_key-updating-a-touch-id-face-id-protected-item
		let updateDataForKey: UpdateDataForKey = { @Sendable data, key, maybeProtection, maybeAuthenticationPrompt in
			guard let protection = maybeProtection else {
				if let authenticationPrompt = maybeAuthenticationPrompt {
					return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
						Task {
							do {
								try wrapped
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
								try wrapped
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
							try wrapped
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
						try wrapped
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
							let value = try wrapped
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
							try wrapped.remove(key)
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
	}
}
