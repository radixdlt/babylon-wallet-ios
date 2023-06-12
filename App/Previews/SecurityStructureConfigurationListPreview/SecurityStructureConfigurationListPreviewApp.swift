import Cryptography
import FactorSourcesClient
import FeaturesPreviewerFeature
import SecurityStructureConfigurationListFeature

// MARK: - SecurityStructureConfigurationListCoordinator.State + EmptyInitializable
extension SecurityStructureConfigurationListCoordinator.State: EmptyInitializable {
	public init() {
		self.init(configList: .init())
	}
}

// MARK: - SecurityStructureConfigurationListCoordinator.View + FeatureView
extension SecurityStructureConfigurationListCoordinator.View: FeatureView {
	public typealias Feature = SecurityStructureConfigurationListCoordinator
}

// MARK: - SecurityStructureConfigurationListCoordinator + PreviewedFeature
extension SecurityStructureConfigurationListCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = SecurityStructureConfiguration
}

// MARK: - SecurityStructureConfigurationListPreviewApp
@main
struct SecurityStructureConfigurationListPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<SecurityStructureConfigurationListCoordinator>.action {
			guard case let .child(.destination(.presented(.createSecurityStructureConfig(.delegate(.done(secStructureConfig)))))) = $0 else { return nil }
			return secStructureConfig

		} withReducer: {
			$0
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .previewApp)
				.dependency(\.appPreferencesClient, .previewApp)
				._printChanges()
		}
	}
}

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

import AppPreferencesClient
extension AppPreferencesClient {
	static let previewApp: Self = with(noop) {
		$0.updatePreferences = { _ in }
	}
}
