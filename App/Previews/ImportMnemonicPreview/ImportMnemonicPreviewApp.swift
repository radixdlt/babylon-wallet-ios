import FeaturePrelude
import ImportMnemonicFeature

@main
struct ImportMnemonicPreviewApp: App {
	var body: some Scene {
		WindowGroup {
			ImportMnemonic.View(
				store: Store(
					initialState: ImportMnemonic.State(
						persistAsMnemonicKind: .offDevice,
						offDeviceMnemonicInfoPrompt: .init(mnemonicWithPassphrase: .testValue)
					),
					reducer: ImportMnemonic()
						._printChanges()
				)
			)
		}
	}
}
