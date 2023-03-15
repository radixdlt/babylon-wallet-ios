import FeaturePrelude
import OnboardingClient

// MARK: - ImportProfile
public struct ImportProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isDisplayingFileImporter = false

		public init(isDisplayingFileImporter: Bool = false) {
			self.isDisplayingFileImporter = isDisplayingFileImporter
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case goBack
		case dismissFileImporter
		case importProfileFileButtonTapped
		case profileImported(Result<URL, NSError>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case goBack
		case imported
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dataReader) var dataReader
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .goBack:
			return .send(.delegate(.goBack))

		case .dismissFileImporter:
			state.isDisplayingFileImporter = false
			return .none

		case .importProfileFileButtonTapped:
			state.isDisplayingFileImporter = true
			return .none

		case let .profileImported(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .profileImported(.success(profileURL)):
			return .run { send in
				let data = try dataReader.contentsOf(profileURL, options: .uncached)
				let snapshot = try jsonDecoder().decode(ProfileSnapshot.self, from: data)
				try await onboardingClient.importProfileSnapshot(snapshot)
				await send(.delegate(.imported))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}
}
