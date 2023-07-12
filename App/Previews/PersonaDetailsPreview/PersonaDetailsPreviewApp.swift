import EditPersonaFeature
import FeaturesPreviewerFeature
import PersonaDetailsFeature
import SwiftUI

// MARK: - PersonaDetailsPreviewApp
@main
struct PersonaDetailsPreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<PersonaDetails>.action {
			guard let result = (/PersonaDetails.Action.child
				.. PersonaDetails.ChildAction.destination
				.. PresentationAction<PersonaDetails.Destination.Action>.presented
				.. PersonaDetails.Destination.Action.editPersona
				.. EditPersona.Action.view
				.. EditPersona.ViewAction.saveButtonTapped
			).extract(from: $0) else {
				return nil
			}

			return TaskResult(
				Result<PersonaDetails.ResultFromFeature, Never>.success(result)
			)
		} withReducer: {
			$0
				.dependency(\.personasClient, with(.noop) { $0.updatePersona = { _ in }})
				._printChanges()
		}
	}
}

// MARK: - PersonaDetails + PreviewedFeature
extension PersonaDetails: PreviewedFeature {
	public typealias ResultFromFeature = EditPersona.Output
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
