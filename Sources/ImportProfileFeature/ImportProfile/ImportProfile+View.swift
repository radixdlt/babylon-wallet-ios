import ComposableArchitecture
import Foundation
import ProfileClient
import SwiftUI

// MARK: - ImportProfile.View
public extension ImportProfile {
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
			observe: { $0 }
		) { viewStore in
			VStack {
				HStack {
					Button(
						action: {
							viewStore.send(.internal(.goBack))
						}, label: {
							Image("arrow-back")
						}
					)
					Spacer()
					Text("Import profile")
					Spacer()
					EmptyView()
				}
				Spacer()

				Button("Import Profile") {
					viewStore.send(.internal(.importProfileFile))
				}
				.buttonStyle(.borderedProminent)
				Spacer()
			}
			.fileImporter(
				isPresented: viewStore.binding(
					get: \.isDisplayingFileImporter,
					send: ImportProfile.Action.internal(.dismissFileimporter)
				),
				allowedContentTypes: [.profile],
				onCompletion: {
					let taskResult: TaskResult<URL> = TaskResult($0)
					viewStore.send(.internal(.importProfileFileResult(taskResult)))
				}
			)
		}
	}
}
