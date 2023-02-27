import DappInteractionFeature
import FeaturePrelude
import HomeFeature
import SettingsFeature

// MARK: - Main.View
extension Main {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension Main.View {
	public var body: some View {
		Home.View(
			store: store.scope(
				state: \.home,
				action: { .child(.home($0)) }
			)
		)
		#if os(iOS)
		// NB: has to be fullScreenCover because of https://stackoverflow.com/q/69101690
		.fullScreenCover(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /Main.Destinations.State.settings,
			action: Main.Destinations.Action.settings,
			content: { AppSettings.View(store: $0) }
		)
		#endif
		.presentsDappInteractions(
			onPresent: { [store = store.stateless] in
				ViewStore(store).send(.view(.dappInteractionPresented))
			},
			onDismiss: { [store = store.stateless] in
				// FIXME: ideally profileClient.getAccounts() would return a stream that'd allow all relevant screens to update independently.
				// Until then, manual reloading is necessary when we come back from interaction flow (in case we created accounts).
				ViewStore(store).send(.child(.home(.view(.appeared))))
			}
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		Main.View(
			store: .init(
				initialState: .previewValue,
				reducer: Main()
			)
		)
	}
}
#endif
