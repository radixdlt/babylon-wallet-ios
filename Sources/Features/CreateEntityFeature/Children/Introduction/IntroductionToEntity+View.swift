import FeaturePrelude

extension IntroductionToEntity.State {
	var viewState: IntroductionToEntity.ViewState {
		.init()
	}
}

// MARK: - IntroductionToEntity.View
extension IntroductionToEntity {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<IntroductionToEntity>

		public init(store: StoreOf<IntroductionToEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: Introduction to \(Entity.entityKind.rawValue)")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - IntroductionToEntity_Preview
struct IntroductionToEntity_Preview: PreviewProvider {
	static var previews: some View {
		IntroductionToEntity<Profile.Network.Persona>.View(
			store: .init(
				initialState: .init(),
				reducer: IntroductionToEntity()
			)
		)
	}
}
#endif
