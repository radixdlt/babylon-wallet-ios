import FeaturesPreviewerFeature
import ImportMnemonicFeature

// MARK: - ImportMnemonic.State + EmptyInitializable
extension ImportMnemonic.State: EmptyInitializable {
	public init() {
		self.init(persistAsMnemonicKind: nil)
	}
}

// MARK: - ImportMnemonic.View + FeatureView
extension ImportMnemonic.View: FeatureView {
	public typealias Feature = ImportMnemonic
}

// MARK: - ImportMnemonic + PreviewedFeature
extension ImportMnemonic: PreviewedFeature {
	public typealias ResultFromFeature = MnemonicWithPassphrase
}

// MARK: - ImportMnemonicPreviewApp
@main
struct ImportMnemonicPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<ImportMnemonic>.delegateAction {
			guard case let .notSavedInProfile(mnemonic) = $0 else { return nil }
			return .success(mnemonic)
		}
	}
}
