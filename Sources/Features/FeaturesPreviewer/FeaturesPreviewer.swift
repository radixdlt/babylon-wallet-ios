@_exported import FeaturePrelude

// MARK: - FeaturesPreviewer
public struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene(
		withFeatureReducer: @escaping (Feature) -> (Reduce<Feature.State, Feature.Action>) = { Reduce($0._printChanges()) },
		resultFrom: @escaping (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?
	) -> some Scene {
		WindowGroup {
			PreviewOfSomeFeatureReducer<Feature>.View(
				store: Store(
					initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
					reducer: PreviewOfSomeFeatureReducer<Feature>(
						withReducer: withFeatureReducer,
						resultFrom: resultFrom
					)
				)
			)
		}
	}
}

// _DependencyKeyWritingReducer<PreviewOfSomeFeatureReducer<CreateSecurityStructureCoordinator>>

//   public convenience init<R: ReducerProtocol>(
// initialState: @autoclosure () -> R.State,
// reducer: R,
// prepareDependencies: ((inout DependencyValues) -> Void)? = nil
// ) where R.State == State, R.Action == Action {
