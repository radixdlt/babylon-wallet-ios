import FeaturePrelude
import Profile

extension DebugInspectProfile.State {
	var viewState: DebugInspectProfile.ViewState {
		.init(profile: profile)
	}
}

// MARK: - DebugInspectProfile.View
extension DebugInspectProfile {
	public struct ViewState: Equatable {
		// TODO: declare some properties
		let profile: Profile
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugInspectProfile>

		public init(store: StoreOf<DebugInspectProfile>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ProfileView(profile: viewStore.profile)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}
