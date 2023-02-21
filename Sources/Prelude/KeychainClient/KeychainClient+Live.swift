import Dependencies
import Foundation
import KeychainAccess

// MARK: - Keychain + Sendable
// This is bad, please migrate to actor.
extension Keychain: @unchecked Sendable {}

// MARK: - KeychainClient + DependencyKey
extension KeychainClient: DependencyKey {
	public static let liveValue: Self = {
		let keychain = Keychain(service: "Radix Wallet")
			.label("Radix Wallet")
			.synchronizable(false) // disables iCloud
			.accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .biometryCurrentSet)

		@Sendable
		func withAttributes(of request: AddKeychainItemWithRequest) -> Keychain {
			var handle = keychain
			if let label = request.label {
				handle = handle.label(label.rawValue.rawValue)
			}
			if let comment = request.comment {
				handle = handle.comment(comment.rawValue.rawValue)
			}
			return handle
		}

		return Self(
			addDataWithoutAuthForKey: { request in
				try withAttributes(of: request)
					.set(request.data, key: request.key.rawValue.rawValue)
			},
			addDataWithAuthForKey: { request in
				try await Task {
					try withAttributes(of: request)
						.accessibility(request.accessibility, authenticationPolicy: request.authenticationPolicy)
						.set(request.data, key: request.key.rawValue.rawValue)
				}.value
			},
			getDataWithoutAuthForKey: { key in
				try keychain.getData(key.rawValue.rawValue)
			},
			getDataWithAuthForKey: { key, authPrompt in
				try await Task {
					try keychain
						.authenticationPrompt(authPrompt.rawValue.rawValue)
						.getData(key.rawValue.rawValue)
				}.value
			},
			updateDataWithoutAuthForKey: { data, key in
				try keychain.set(data, key: key.rawValue.rawValue)
			},
			updateDataWithAuthForKey: { data, key, authPrompt in
				try await Task {
					try keychain
						.authenticationPrompt(authPrompt.rawValue.rawValue)
						.set(data, key: key.rawValue.rawValue)
				}.value
			},
			removeDataForKey: { key in
				try keychain.remove(key.rawValue.rawValue)
			},
			removeAllItems: {
				try keychain.removeAll()
			}
		)
	}()
}
