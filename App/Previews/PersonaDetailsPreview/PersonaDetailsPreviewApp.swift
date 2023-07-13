import FeaturesPreviewerFeature
import PersonaDetailsFeature
import SwiftUI

// MARK: - PersonaDetailsPreviewApp
@main
struct PersonaDetailsPreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<PersonaDetails>.delegateAction { _ in
			nil
		}
	}
}

// MARK: - PersonaDetails + PreviewedFeature
extension PersonaDetails: PreviewedFeature {
	public typealias ResultFromFeature = Profile.Network.Account
}

// MARK: - PersonaDetails + EmptyInitializable
extension PersonaDetails: EmptyInitializable {}

// MARK: - PersonaDetails.State + EmptyInitializable
extension PersonaDetails.State: EmptyInitializable {
	public init() {
		self.init(.general(
			.previewValue0,
			dApps: []
		))
	}
}

// MARK: - PersonaDetails.View + FeatureView
extension PersonaDetails.View: FeatureView {
	public typealias Feature = PersonaDetails
}
