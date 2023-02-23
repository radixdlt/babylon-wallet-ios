import Dependencies
import Foundation
import KeychainAccess

// MARK: - Keychain + Sendable
// This is bad, please migrate to actor.
extension Keychain: @unchecked Sendable {}

// MARK: - KeychainClient + DependencyKey
extension KeychainClient: DependencyKey {
	public static let liveValue: Self = {
		final actor KeychainActor: GlobalActor {
			static let shared = KeychainActor()
			private let keychain: Keychain
			private init() {
				self.keychain = Keychain(service: "Radix Wallet")
			}

			private func withAttributes(of request: SetKeychainItemWithRequest) -> Keychain {
				var handle = keychain.synchronizable(request.iCloudSyncEnabled)
				if let label = request.label {
					handle = handle.label(label.rawValue.rawValue)
				}
				if let comment = request.comment {
					handle = handle.comment(comment.rawValue.rawValue)
				}
				return handle
			}

			typealias Key = KeychainClient.Key
			typealias Label = KeychainClient.Label
			typealias Comment = KeychainClient.Comment
			typealias AuthenticationPrompt = KeychainClient.AuthenticationPrompt

			func setDataWithoutAuth(
				_ request: SetItemWithoutAuthRequest
			) async throws {
				try await Task {
					try withAttributes(of: request)
						.accessibility(request.accessibility)
						.set(request.data, key: request.key.rawValue.rawValue)

				}.value
			}

			func setDataWithAuthForKey(
				_ request: SetItemWithAuthRequest
			) async throws {
				try await Task {
					try withAttributes(of: request)
						.accessibility(request.accessibility, authenticationPolicy: request.authenticationPolicy)
						.set(request.data, key: request.key.rawValue.rawValue)
				}.value
			}

			func getDataWithoutAuth(
				forKey key: Key
			) async throws -> Data? {
				try await Task {
					try keychain.getData(key.rawValue.rawValue)
				}.value
			}

			func getDataWithAuthForKey(
				forKey key: Key,
				authPrompt: AuthenticationPrompt
			) async throws -> Data? {
				try await Task {
					try keychain
						.authenticationPrompt(authPrompt.rawValue.rawValue)
						.getData(key.rawValue.rawValue)
				}.value
			}

			func removeData(
				forKey key: Key
			) async throws {
				try await Task {
					try keychain.remove(key.rawValue.rawValue)
				}.value
			}

			func removeAllItems() async throws {
				try await Task {
					try keychain.removeAll()
				}.value
			}
		}

		return Self(
			setDataWithoutAuthForKey: { try await KeychainActor.shared.setDataWithoutAuth($0) },
			setDataWithAuthForKey: { try await KeychainActor.shared.setDataWithAuthForKey($0) },
			getDataWithoutAuthForKey: { try await KeychainActor.shared.getDataWithoutAuth(forKey: $0) },
			getDataWithAuthForKey: { try await KeychainActor.shared.getDataWithAuthForKey(forKey: $0, authPrompt: $1) },
			removeDataForKey: { try await KeychainActor.shared.removeData(forKey: $0) },
			removeAllItems: { try await KeychainActor.shared.removeAllItems() }
		)
	}()
}
