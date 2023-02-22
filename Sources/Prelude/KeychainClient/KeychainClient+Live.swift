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

			private func withAttributes(of request: AddKeychainItemWithRequest) -> Keychain {
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

			@Sendable
			fileprivate func addDataWithoutAuth(
				_ request: AddItemWithoutAuthRequest
			) async throws {
				try withAttributes(of: request)
					.set(request.data, key: request.key.rawValue.rawValue)
			}

			@Sendable
			fileprivate func addDataWithAuthForKey(
				_ request: AddItemWithAuthRequest
			) async throws {
				try await Task {
					try withAttributes(of: request)
						.accessibility(request.accessibility, authenticationPolicy: request.authenticationPolicy)
						.set(request.data, key: request.key.rawValue.rawValue)
				}.value
			}

			@Sendable
			fileprivate func getDataWithoutAuth(
				forKey key: Key
			) async throws -> Data? {
				try keychain.getData(key.rawValue.rawValue)
			}

			@Sendable
			fileprivate func getDataWithAuthForKey(
				forKey key: Key,
				authPrompt: AuthenticationPrompt
			) async throws -> Data? {
				try await Task {
					try keychain
						.authenticationPrompt(authPrompt.rawValue.rawValue)
						.getData(key.rawValue.rawValue)
				}.value
			}

			@Sendable
			fileprivate func updateDataWithoutAuth(
				_ data: Data,
				forKey key: Key
			) async throws {
				try keychain.set(data, key: key.rawValue.rawValue)
			}

			@Sendable
			fileprivate func updateDataWithAuthForKey(
				_ data: Data,
				forKey key: Key,
				authPrompt: AuthenticationPrompt
			) async throws {
				try await Task {
					try keychain
						.authenticationPrompt(authPrompt.rawValue.rawValue)
						.set(data, key: key.rawValue.rawValue)
				}.value
			}

			@Sendable
			fileprivate func removeData(
				forKey key: Key
			) async throws {
				try keychain.remove(key.rawValue.rawValue)
			}

			@Sendable
			fileprivate func removeAllItems() async throws {
				try keychain.removeAll()
			}
		}

		return Self(
			addDataWithoutAuthForKey: { try await KeychainActor.shared.addDataWithoutAuth($0) },
			addDataWithAuthForKey: { try await KeychainActor.shared.addDataWithAuthForKey($0) },
			getDataWithoutAuthForKey: { try await KeychainActor.shared.getDataWithoutAuth(forKey: $0) },
			getDataWithAuthForKey: { try await KeychainActor.shared.getDataWithAuthForKey(forKey: $0, authPrompt: $1) },
			updateDataWithoutAuthForKey: { try await KeychainActor.shared.updateDataWithoutAuth($0, forKey: $1) },
			updateDataWithAuthForKey: { try await KeychainActor.shared.updateDataWithAuthForKey($0, forKey: $1, authPrompt: $2) },
			removeDataForKey: { try await KeychainActor.shared.removeData(forKey: $0) },
			removeAllItems: { try await KeychainActor.shared.removeAllItems() }
		)
	}()
}
