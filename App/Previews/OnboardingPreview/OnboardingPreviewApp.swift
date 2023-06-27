import FeaturesPreviewerFeature
import OnboardingFeature
import SwiftUI

// MARK: - OnboardingPreviewApp
@main
struct OnboardingPreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<OnboardingCoordinator>.delegateAction {
			guard case let .completed = $0 else { return nil }
			return nil
		} withReducer: {
			$0
				.dependency(\.factorSourcesClient, .previewApp)
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

import Cryptography
import FactorSourcesClient

extension FactorSourcesClient {
	static let previewApp: Self =
		with(noop) {
			$0.saveFactorSource = { _ in }
			$0.getFactorSources = { @Sendable in
				let device = try! DeviceFactorSource.babylon(
					mnemonicWithPassphrase: .init(
						mnemonic: Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
					)
				)
				return NonEmpty<IdentifiedArrayOf<FactorSource>>.init(rawValue: [device.embed()])!
			}
		}
}
