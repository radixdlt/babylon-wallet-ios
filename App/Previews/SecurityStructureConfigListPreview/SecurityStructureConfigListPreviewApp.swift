import FeaturesPreviewerFeature
import SecurityStructureConfigsFeature

// MARK: - SecurityStructureConfigs.State + EmptyInitializable
extension SecurityStructureConfigs.State: EmptyInitializable {}

// MARK: - SecurityStructureConfigs.View + FeatureViewProtocol
extension SecurityStructureConfigs.View: FeatureViewProtocol {
	public typealias Feature = SecurityStructureConfigs
}

// MARK: - SecurityStructureConfigs + PreviewedFeature
extension SecurityStructureConfigs: PreviewedFeature {
	public typealias ResultFromFeature = Never
}

// MARK: - SecurityStructureConfigListPreviewApp
@main
struct SecurityStructureConfigListPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<SecurityStructureConfigs>.scene { _ in nil
//			guard case let .notSavedInProfile(mnemonic) = $0 else { return nil }
//			return .success(mnemonic)
		}
	}
}
