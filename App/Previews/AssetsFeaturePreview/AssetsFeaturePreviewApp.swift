import AssetsFeature
import FeaturesPreviewerFeature
import Prelude
import SwiftUI

// MARK: - AssetsFeaturePreviewApp
@main
struct AssetsFeaturePreviewApp: App {
	var body: some Scene {
		FeaturesPreviewer<AssetsView>.action { _ in
			nil
		}
	}
}

// MARK: - AssetsView + PreviewedFeature
extension AssetsView: PreviewedFeature {
	public typealias ResultFromFeature = Prelude.Unit
}

// MARK: - AssetsView + EmptyInitializable
extension AssetsView: EmptyInitializable {}

// MARK: - AssetsView.State + EmptyInitializable
extension AssetsView.State: EmptyInitializable {
	public init() {
		self.init(account: .previewValue0, mode: .normal)
	}
}

// MARK: - AssetsView.View + FeatureView
extension AssetsView.View: FeatureView {
	public typealias Feature = AssetsView
}
