@_exported import FeaturePrelude

// MARK: - FeaturesPreviewer
public struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene(
		resultFrom: @escaping (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?,
		withReducer: (PreviewOfSomeFeatureReducer<Feature>) -> any ReducerProtocol<PreviewOfSomeFeatureReducer<Feature>.State, PreviewOfSomeFeatureReducer<Feature>.Action> = { $0._printChanges() }
	) -> some Scene {
		WindowGroup {
			PreviewOfSomeFeatureReducer<Feature>.View(
				store: Store(
					initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
					reducer: Reduce(withReducer(
						PreviewOfSomeFeatureReducer<Feature>(resultFrom: resultFrom)
					))
				)
			)
		}
	}
}
