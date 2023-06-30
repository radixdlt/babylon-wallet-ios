import FeaturesPreviewerFeature
import ManageTrustedContactFactorSourceFeature

// MARK: - ManageTrustedContactFactorSource.State + EmptyInitializable
extension ManageTrustedContactFactorSource.State: EmptyInitializable {}

// MARK: - ManageTrustedContactFactorSource.View + FeatureView
extension ManageTrustedContactFactorSource.View: FeatureView {
	public typealias Feature = ManageTrustedContactFactorSource
}

// MARK: - ManageTrustedContactFactorSource + PreviewedFeature
extension ManageTrustedContactFactorSource: PreviewedFeature {
	public typealias ResultFromFeature = TrustedContactFactorSource
}

// MARK: - AddTrustedContactPreviewApp
@main
struct AddTrustedContactPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<ManageTrustedContactFactorSource>.delegateAction {
			guard case let .done(trustedContactFS) = $0 else { return nil }
			return trustedContactFS
		} withReducer: {
			$0
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .previewApp)
				._printChanges()
		}
	}
}

import FactorSourcesClient
extension FactorSourcesClient {
	static let previewApp: Self =
		with(noop) {
			$0.saveFactorSource = { _ in }
		}
}
