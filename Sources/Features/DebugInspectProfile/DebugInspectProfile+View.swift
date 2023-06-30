import FeaturePrelude
import Profile

extension DebugInspectProfile.State {
	var viewState: DebugInspectProfile.ViewState {
		.init(profile: profile, mode: mode, json: json)
	}
}

// MARK: - DebugInspectProfile.View
extension DebugInspectProfile {
	public struct ViewState: Equatable {
		let profile: Profile
		let mode: DebugInspectProfile.State.Mode
		let json: String?
	}

	@MainActor

	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugInspectProfile>

		public init(store: StoreOf<DebugInspectProfile>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Group {
					if let json = viewStore.json, viewStore.mode == .rawJSON {
						JSONView(jsonString: json)
					} else {
						ProfileView(profile: viewStore.profile)
					}
				}
				.toolbar {
					ToolbarItem(placement: .navigationBarTrailing) {
						Button("Copy JSON") {
							viewStore.send(.copyJSONButtonTapped)
						}
						.buttonStyle(.borderedProminent)
					}

					ToolbarItem(placement: .navigationBarTrailing) {
						Button(viewStore.mode.toggleButtonText) {
							viewStore.send(.toggleModeButtonTapped)
						}
						.buttonStyle(.borderedProminent)
					}
				}
			}
		}
	}
}

extension DebugInspectProfile.State.Mode {
	var toggleButtonText: String {
		switch self {
		case .rawJSON: return "struct"
		case .structured: return "JSON"
		}
	}
}
