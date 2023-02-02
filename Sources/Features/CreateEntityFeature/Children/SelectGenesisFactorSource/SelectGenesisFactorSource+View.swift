import FeaturePrelude

// MARK: - SelectGenesisFactorSource.View
public extension SelectGenesisFactorSource {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SelectGenesisFactorSource>

		public init(store: StoreOf<SelectGenesisFactorSource>) {
			self.store = store
		}
	}
}

public extension SelectGenesisFactorSource.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				// FIXME: appStore submission: implement this screen with a picker
				VStack {
					Spacer()
					Button("Confirm OnDevice factor source") {
						viewStore.send(.confirmOnDeviceFactorSource)
					}
					Spacer()
				}
			}
		}
	}
}

// MARK: - SelectGenesisFactorSource.View.ViewState
extension SelectGenesisFactorSource.View {
	struct ViewState: Equatable {
		init(state: SelectGenesisFactorSource.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectGenesisFactorSource_Preview
struct SelectGenesisFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		SelectGenesisFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectGenesisFactorSource()
			)
		)
	}
}
#endif
