import FeaturePrelude
import ImportMnemonicFeature

@main
struct ImportMnemonicPreviewApp: App {
	var body: some Scene {
		WindowGroup {
			ImportMnemonic.View(
				store: Store(
					initialState: ImportMnemonic.State(saveInProfile: false),
					reducer: ImportMnemonic()._printChanges()
				)
			)
		}
	}
}
