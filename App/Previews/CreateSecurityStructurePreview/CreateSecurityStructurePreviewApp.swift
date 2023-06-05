import CreateSecurityStructureFeature
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
		FeaturesPreviewer<CreateSecurityStructureCoordinator>.scene { _ in
//			guard case let .done(structure) = $0 else { return nil }
//			return structure
			nil
		}
	}
}
