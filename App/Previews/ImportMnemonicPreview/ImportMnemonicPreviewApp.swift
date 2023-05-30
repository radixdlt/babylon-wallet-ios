import FeaturePrelude
import ImportMnemonicFeature

@main
struct ImportMnemonicPreviewApp: App {
	var body: some Scene {
		WindowGroup {
			ImportMnemonic.View(
				store: Store(
					initialState: ImportMnemonic.State(
						saveInProfileKind: .offDevice
					),
					reducer: ImportMnemonic()
						._printChanges()
				)
			)
		}
	}
}
