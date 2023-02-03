import FeaturePrelude
import ProfileClient

// MARK: - ImportProfile
public struct ImportProfile: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient
	public init() {}
}

public extension ImportProfile {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				try await profileClient.injectProfileSnapshot(snapshot)
				await send(.delegate(.imported))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .delegate:
			return .none
		}
	}
}
