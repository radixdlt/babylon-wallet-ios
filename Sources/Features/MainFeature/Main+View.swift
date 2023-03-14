import DappInteractionFeature
import FeaturePrelude
import HomeFeature
import SettingsFeature

// MARK: - Main.View
extension Main {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Main>

		public init(store: StoreOf<Main>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				Home.View(
					store: store.scope(
						state: \.home,
						action: { .child(.home($0)) }
					)
				)
				#if os(iOS)
				.navigationDestination(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /Main.Destinations.State.settings,
					action: Main.Destinations.Action.settings,
					destination: { AppSettings.View(store: $0) }
				)
				#endif
			}
			.presentsDappInteractions(
				canPresentInteraction: { [store = store.actionless] in
					ViewStore(store).canPresentDappInteraction
				}
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct MainView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		Main.View(
			store: .init(
				initialState: .previewValue,
				reducer: Main()
			)
		)
	}
}

extension Main.State {
	public static let previewValue = Self(home: .previewValue)
}
#endif
