import FeaturePrelude

// MARK: - NewProfile.View
public extension NewProfile {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewProfile>

		public init(store: StoreOf<NewProfile>) {
			self.store = store
		}
	}
}

public extension NewProfile.View {
	var body: some View {
		ForceFullScreen {
			Image(asset: AssetResource.splash)
				.resizable()
				.scaledToFill()
		}
		.edgesIgnoringSafeArea(.all)
		.onAppear {
			ViewStore(store.stateless).send(.view(.appeared))
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - NewProfile_Preview
struct NewProfile_Preview: PreviewProvider {
	static var previews: some View {
		NewProfile.View(
			store: .init(
				initialState: .previewValue,
				reducer: NewProfile()
			)
		)
	}
}
#endif
