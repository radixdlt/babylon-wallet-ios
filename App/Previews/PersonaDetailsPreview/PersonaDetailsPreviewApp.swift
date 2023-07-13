import EditPersonaFeature
import FeaturesPreviewerFeature
import PersonaDetailsFeature
import SwiftUI

// MARK: - PersonaDetailsPreviewApp
@main
struct PersonaDetailsPreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<PersonaDetails>.action {
			guard let persona = (/PersonaDetails.Action.child
				.. PersonaDetails.ChildAction.destination
				.. PresentationAction<PersonaDetails.Destination.Action>.presented
				.. PersonaDetails.Destination.Action.editPersona
				.. EditPersona.Action.delegate
				.. EditPersona.DelegateAction.personaSaved
			).extract(from: $0) else {
				return nil
			}

			return TaskResult(
				Result<PersonaDetails.ResultFromFeature, Never>.success(persona)
			)
		} withReducer: {
			$0
				.dependency(\.personasClient, with(.noop) { $0.updatePersona = { @Sendable _ in }})
				._printChanges()
		}
	}
}

// MARK: - PersonaDetails + PreviewedFeature
extension PersonaDetails: PreviewedFeature {
	public typealias ResultFromFeature = Profile.Network.Persona
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
