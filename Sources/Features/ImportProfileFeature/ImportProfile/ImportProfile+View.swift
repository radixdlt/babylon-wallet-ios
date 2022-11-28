import Common
import ComposableArchitecture
import Foundation
import ProfileClient
import SwiftUI

// MARK: - ImportProfile.View
public extension ImportProfile {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ImportProfile>
		public init(store: StoreOf<ImportProfile>) {
			self.store = store
		}
	}
}

public extension ImportProfile.View {
	var body: some View {
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
					Text("Import profile")
//					Text(L10n.ImportProfile.importProfile.title)
					Spacer()
					EmptyView()
				}
				Spacer()

				Button("Import Profile") {
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
