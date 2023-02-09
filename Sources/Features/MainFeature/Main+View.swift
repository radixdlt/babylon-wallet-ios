import DappInteractionFeature
import FeaturePrelude
import HomeFeature
import SettingsFeature

// MARK: - Main.View
public extension Main {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Main.View {
	var body: some View {
		ZStack {
			Home.View(
				store: store.scope(
					state: \.home,
					action: { .child(.home($0)) }
				)
			)
			.zIndex(0)

			IfLetStore(
				store.scope(
					state: \.settings,
					action: { .child(.settings($0)) }
				),
				then: { AppSettings.View(store: $0) }
			)
			.zIndex(1)
		}
		.presentsDappInteractions(onDismiss: { [store = store.stateless] in
			// FIXME: ideally profileClient.getAccounts() would return a stream that'd allow all relevant screens to update independently.
			// Until then, manual reloading is necessary when we come back from interaction flow (in case we created accounts).
			ViewStore(store).send(.child(.home(.view(.didAppear))))
		})
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
