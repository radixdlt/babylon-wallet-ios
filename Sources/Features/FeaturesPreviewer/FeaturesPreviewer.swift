@_exported import FeaturePrelude

// MARK: - FeaturesPreviewer
public struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene(
		resultFrom: @escaping (Feature.DelegateAction) -> Feature.ResultFromFeature?
	) -> some Scene {
		WindowGroup {
			PreviewOfSomeFeatureReducer<Feature>.View(
				store: Store(
					initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
					reducer: PreviewOfSomeFeatureReducer<Feature>(resultFrom: resultFrom)
						._printChanges()
				)
			)
		}
	}
}
