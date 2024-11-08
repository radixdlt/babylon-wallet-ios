import ComposableArchitecture
@_exported import SwiftUI

// MARK: - FeaturesPreviewer
struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	/// Extracts a "result" from `Feature.Action`
	static func action(
		wrapInNavigationView: Bool = false,
		resultFromAction: @escaping (Feature.Action) -> TaskResult<Feature.ResultFromFeature>?,
		withReducer: @escaping (PreviewOfSomeFeatureReducer<Feature>) -> any Reducer<PreviewOfSomeFeatureReducer<Feature>.State, PreviewOfSomeFeatureReducer<Feature>.Action> = { $0._printChanges() }
	) -> some Scene {
		WindowGroup {
			let store = Store(
				initialState: PreviewOfSomeFeatureReducer<Feature>.State()
			) {
				Reduce(withReducer(
					PreviewOfSomeFeatureReducer<Feature>(resultFromAction: resultFromAction)
				))
			}

			if wrapInNavigationView {
				NavigationView {
					PreviewOfSomeFeatureReducer<Feature>.View(store: store)
				}
			} else {
				PreviewOfSomeFeatureReducer<Feature>.View(store: store)
			}
		}
	}

	/// Extracts a "result" from `Feature.DelegateAction`
	static func delegateAction(
		wrapInNavigationView: Bool = false,
		resultFromDelegateAction: @escaping (Feature.DelegateAction) -> TaskResult<Feature.ResultFromFeature>?,
		withReducer: @escaping (PreviewOfSomeFeatureReducer<Feature>) -> any Reducer<PreviewOfSomeFeatureReducer<Feature>.State, PreviewOfSomeFeatureReducer<Feature>.Action> = { $0._printChanges() }
	) -> some Scene {
		action(
			wrapInNavigationView: wrapInNavigationView,
			resultFromAction: {
				switch $0 {
				case let .delegate(delegateAction):
					resultFromDelegateAction(delegateAction)
				default: nil
				}
			},
			withReducer: withReducer
		)
	}
}
