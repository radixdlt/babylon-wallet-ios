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
			guard case let .completed = $0 else { return nil }
			return .success(3)
		} withReducer: { onboarding in
			CombineReducers {
				onboarding
					.dependency(\.cacheClient, .noop)
					.dependency(\.userDefaultsClient, .noop)
					.dependency(\.radixConnectClient, .previewValue)
					.dependency(\.appPreferencesClient, .previewValue)
					.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }
					.dependency(\.factorSourcesClient, .liveValue)
			}
			._printChanges()
		}
	}
}

// MARK: - OnboardingCoordinator + PreviewedFeature
extension OnboardingCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = Int
}

// MARK: - OnboardingCoordinator + EmptyInitializable
extension OnboardingCoordinator: EmptyInitializable {}

// MARK: - OnboardingCoordinator.State + EmptyInitializable
extension OnboardingCoordinator.State: EmptyInitializable {}

// MARK: - OnboardingCoordinator.View + FeatureView
extension OnboardingCoordinator.View: FeatureView {
	public typealias Feature = OnboardingCoordinator
}
