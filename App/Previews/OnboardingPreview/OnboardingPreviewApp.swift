import AccountsClientLive
import FactorSourcesClientLive
import FeaturesPreviewerFeature
import OnboardingClientLive
import OnboardingFeature
import SwiftUI

// MARK: - OnboardingPreviewApp
@main
struct OnboardingPreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<OnboardingCoordinator>.delegateAction {
			guard case let .completed(result) = $0 else {
				return nil
			}

			return result.map(TaskResult.success)
		} withReducer: { onboarding in
			CombineReducers {
				onboarding
					.dependency(\.userDefaultsClient, .noop)
					.dependency(\.appPreferencesClient, .previewValue)
					.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }

				Reduce { _, action in
					if case .child(.previewResult(.delegate(.restart))) = action {
						return .run { _ in
							@Dependency(\.appPreferencesClient) var appPreferences
							try? await appPreferences.deleteProfileAndFactorSources(false)
						}
					}

					return .none
				}
			}
			._printChanges()
		}
	}
}

// MARK: - OnboardingCoordinator + PreviewedFeature
extension OnboardingCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = Profile.Network.Account
}

// MARK: - OnboardingCoordinator + EmptyInitializable
extension OnboardingCoordinator: EmptyInitializable {}

// MARK: - OnboardingCoordinator.State + EmptyInitializable
extension OnboardingCoordinator.State: EmptyInitializable {}

// MARK: - OnboardingCoordinator.View + FeatureView
extension OnboardingCoordinator.View: FeatureView {
	public typealias Feature = OnboardingCoordinator
}
