import FeaturesPreviewerFeature
import ImportMnemonicFeature

// MARK: - ImportMnemonic.State + EmptyInitializable
extension ImportMnemonic.State: EmptyInitializable {
	public init() {
		self.init(persistAsMnemonicKind: nil)
	}
}

// MARK: - ImportMnemonic.View + FeatureViewProtocol
extension ImportMnemonic.View: FeatureViewProtocol {
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
		FeaturesPreviewer<ImportMnemonic>.scene {
			guard case let .notSavedInProfile(mnemonic) = $0 else { return nil }
			return .success(mnemonic)
		}
	}
}
