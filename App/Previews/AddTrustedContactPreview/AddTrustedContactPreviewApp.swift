import AddTrustedContactFactorSourceFeature
import FeaturesPreviewerFeature

// MARK: - AddTrustedContactFactorSource.State + EmptyInitializable
extension AddTrustedContactFactorSource.State: EmptyInitializable {}

// MARK: - AddTrustedContactFactorSource.View + FeatureView
extension AddTrustedContactFactorSource.View: FeatureView {
	public typealias Feature = AddTrustedContactFactorSource
}

// MARK: - AddTrustedContactFactorSource + PreviewedFeature
extension AddTrustedContactFactorSource: PreviewedFeature {
	public typealias ResultFromFeature = TrustedContactFactorSource
}

// MARK: - AddTrustedContactPreviewApp
@main
struct AddTrustedContactPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<AddTrustedContactFactorSource>.delegateAction {
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
