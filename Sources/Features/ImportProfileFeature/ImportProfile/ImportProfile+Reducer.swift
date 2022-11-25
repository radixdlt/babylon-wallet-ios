import ComposableArchitecture
import Data
import ErrorQueue
import Foundation
import JSON
import KeychainClientDependency
import Profile

// MARK: - ImportProfile
public struct ImportProfile: ReducerProtocol {
	@Dependency(\.data) var data
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.keychainClient) var keychainClient
	public init() {}
}

// MARK: ReducerProtocol Conformance
public extension ImportProfile {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .internal(.view(.goBack)):
			return .run { send in
				await send(.delegate(.goBack))
			}

		case .internal(.view(.dismissFileImporter)):
			state.isDisplayingFileImporter = false
			return .none

		case .internal(.view(.importProfileFileButtonTapped)):
			state.isDisplayingFileImporter = true
			return .none

		case let .internal(.view(.profileImported(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .internal(.view(.profileImported(.success(profileURL)))):
			return .run { send in
				let data = try data(contentsOf: profileURL, options: .uncached)
				let snapshot: ProfileSnapshot
				do {
					snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				} catch {
					#if DEBUG
					try? await keychainClient.removeAllFactorSourcesAndProfileSnapshot()
					try? await keychainClient.removeProfileSnapshot()
					#else
					// TODO: Handle conflicting JSON formats of Profile somehow..?
					#endif // DEBUG
					throw error
				}
				try await keychainClient.updateProfileSnapshot(profileSnapshot: snapshot)
				await send(.delegate(.importedProfileSnapshot(snapshot)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .delegate:
			return .none
		}
	}
}
