import CreateSecurityStructureFeature
import FeaturePrelude

@main
struct CreateSecurityStructurePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			CreateSecurityStructureCoordinator.View(
				store: Store(
					initialState: CreateSecurityStructureCoordinator.State(),
					reducer: CreateSecurityStructureCoordinator()
						._printChanges()
				)
			)
		}
	}
}
