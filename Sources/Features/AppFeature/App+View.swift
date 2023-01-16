import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: - App.View
public extension App {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension App.View {
	var body: some View {
		VStack(spacing: .zero) {
			Text(L10n.App.developmentOnlyInfo)
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(.small3)
				.background(Color.app.orange2)
				.textStyle(.body2HighImportance)

			SwitchStore(store.scope(state: \.root)) {
				CaseLet(
					state: /App.State.Root.main,
					action: { App.Action.child(.main($0)) },
					then: { Main.View(store: $0) }
				)

				CaseLet(
					state: /App.State.Root.onboarding,
					action: { App.Action.child(.onboarding($0)) },
					then: { Onboarding.View(store: $0) }
				)

				CaseLet(
					state: /App.State.Root.splash,
					action: { App.Action.child(.splash($0)) },
					then: { Splash.View(store: $0) }
				)
			}
			.alert(
				store.scope(
					state: \.errorAlert,
					action: { .view($0) }
				),
				dismiss: .errorAlertDismissButtonTapped
			)
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
			.overlayLoadingView()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(
				initialState: .init(),
				reducer: App()
			)
		)
	}
}

#endif
