import ComposableArchitecture
import DesignSystem
import ImportProfileFeature
import SwiftUI

// MARK: - Onboarding.View
public extension Onboarding {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Onboarding>

		public init(store: StoreOf<Onboarding>) {
			self.store = store
		}
	}
}

public extension Onboarding.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ZStack {
				IfLetStore(
					store.scope(
						state: \.importProfile,
						action: { .child(.importProfile($0)) }
					),
					then: { importProfileStore in
						ForceFullScreen {
							ImportProfile.View(store: importProfileStore)
						}
					}
				)
				.zIndex(2)
			}
		}
	}
}

// MARK: - Onboarding.View.ViewState
extension Onboarding.View {
	struct ViewState: Equatable {
		public var importProfile: ImportProfile.State?
		public init(state: Onboarding.State) {
			importProfile = state.importProfile
		}
	}
}
