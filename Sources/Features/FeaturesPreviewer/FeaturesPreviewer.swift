@_exported import FeaturePrelude

// MARK: - FeaturesPreviewer
public struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene(
		wrapInNavigationView: Bool = false,
		resultFrom: @escaping (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?,
		withReducer: (PreviewOfSomeFeatureReducer<Feature>) -> any ReducerProtocol<PreviewOfSomeFeatureReducer<Feature>.State, PreviewOfSomeFeatureReducer<Feature>.Action> = { $0._printChanges() }
	) -> some Scene {
		WindowGroup {
			let store = Store(
				initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
				reducer: Reduce(withReducer(
					PreviewOfSomeFeatureReducer<Feature>(resultFrom: resultFrom)
				))
			)

			if wrapInNavigationView {
				NavigationView {
					PreviewOfSomeFeatureReducer<Feature>.View(
						store: store
					)
				}
			} else {
				PreviewOfSomeFeatureReducer<Feature>.View(
					store: store
				)
			}
		}
	}
}
