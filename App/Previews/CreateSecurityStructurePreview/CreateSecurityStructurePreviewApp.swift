import CreateSecurityStructureFeature
import Cryptography
import FeaturesPreviewerFeature

// MARK: - CreateSecurityStructureCoordinator.State + EmptyInitializable
extension CreateSecurityStructureCoordinator.State: EmptyInitializable {}

// MARK: - CreateSecurityStructureCoordinator.View + FeatureViewProtocol
extension CreateSecurityStructureCoordinator.View: FeatureViewProtocol {
	public typealias Feature = CreateSecurityStructureCoordinator
}

// MARK: - CreateSecurityStructureCoordinator + PreviewedFeature
extension CreateSecurityStructureCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = SecurityStructureConfiguration
}

// MARK: - CreateSecurityStructurePreviewApp
@main
struct CreateSecurityStructurePreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<CreateSecurityStructureCoordinator>.scene {
			guard case let .done(secStructureConfig) = $0 else { return nil }
			return secStructureConfig
		} withReducer: {
			$0
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .previewApp)
				._printChanges()
		}
	}
}

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
