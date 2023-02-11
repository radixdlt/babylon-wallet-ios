import FeaturePrelude

// MARK: - ImportProfile.View
extension ImportProfile {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<ImportProfile>
		public init(store: StoreOf<ImportProfile>) {
			self.store = store
		}
	}
}

extension ImportProfile.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: { $0 },
			send: { .view($0) }
		) { viewStore in
			VStack {
				HStack {
					Button(
						action: {
							viewStore.send(.goBack)
						}, label: {
							Image(asset: AssetResource.arrowBack)
						}
					)
					Spacer()
					Text(L10n.ImportProfile.importProfile)
					Spacer()
					EmptyView()
				}
				Spacer()

				Button(L10n.ImportProfile.importProfile.capitalized) {
					viewStore.send(.importProfileFileButtonTapped)
				}
				.buttonStyle(.borderedProminent)
				Spacer()
			}
			.fileImporter(
				isPresented: viewStore.binding(
					get: \.isDisplayingFileImporter,
					send: .dismissFileImporter
				),
				allowedContentTypes: [.profile],
				onCompletion: { viewStore.send(.profileImported($0.mapError { $0 as NSError })) }
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ImportProfile_Preview: PreviewProvider {
	static var previews: some View {
		ImportProfile.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportProfile()
			)
		)
	}
}
#endif
