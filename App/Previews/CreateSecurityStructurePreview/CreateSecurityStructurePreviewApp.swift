import CreateSecurityStructureFeature
import FeaturePrelude

@main
struct CreateSecurityStructurePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			CreateSecurityStructure.View(
				store: Store(
					initialState: CreateSecurityStructure.State(),
					reducer: CreateSecurityStructure()
						._printChanges()
				)
			)
		}
	}
}
