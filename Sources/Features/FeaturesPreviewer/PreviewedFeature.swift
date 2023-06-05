import FeaturePrelude

// MARK: - PreviewedFeature
public protocol PreviewedFeature: FeatureReducer & EmptyInitializable where View: FeatureViewProtocol, View.Feature == Self, State: EmptyInitializable {
	associatedtype ResultFromFeature: Hashable & Sendable
}
