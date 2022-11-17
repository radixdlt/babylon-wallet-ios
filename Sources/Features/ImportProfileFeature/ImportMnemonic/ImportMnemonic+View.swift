import Common
import ComposableArchitecture
import DesignSystem
import Foundation
import SwiftUI

// MARK: - ImportMnemonic.View
public extension ImportMnemonic {
	struct View: SwiftUI.View {
		let store: StoreOf<ImportMnemonic>
		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}
	}
}

public extension ImportMnemonic.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack {
				HStack {
					Button(
						action: {
							viewStore.send(.goBackButtonTapped)
						}, label: {
							Image(asset: AssetResource.arrowBack)
						}
					)
					Spacer()
					Text("Import Mnemonic")
					Spacer()
					EmptyView()
				}
				Spacer()

				TextField(
					"Mnemonic phrasec",
					text: viewStore.binding(
						get: \.phraseOfMnemonicToImport,
						send: { .phraseOfMnemonicToImportChanged($0) }
					)
				)
				Button(
					"Import mnemonic"
				) {
					viewStore.send(.importMnemonicButtonTapped)
				}
				.enabled(viewStore.canImportMnemonic)

				Button(
					"Save imported mnemonic"
				) {
					viewStore.send(.saveImportedMnemonicButtonTapped)
				}
				.enabled(viewStore.canSaveImportedMnemonic)

				Button(
					"Profile from snapshot"
				) {
					viewStore.send(.importProfileFromSnapshotButtonTapped)
				}
				.enabled(viewStore.canImportProfileFromSnapshot)
			}
		}
		.buttonStyle(.primary)
	}
}

// MARK: - ImportMnemonic.View.ViewState
public extension ImportMnemonic.View {
	struct ViewState: Equatable {
		public let phraseOfMnemonicToImport: String
		public let canImportMnemonic: Bool
		public let canSaveImportedMnemonic: Bool
		public let canImportProfileFromSnapshot: Bool
		public init(state: ImportMnemonic.State) {
			phraseOfMnemonicToImport = state.phraseOfMnemonicToImport
			canImportMnemonic = !state.phraseOfMnemonicToImport.isEmpty
			canSaveImportedMnemonic = state.importedMnemonic != nil
			canImportProfileFromSnapshot = state.savedMnemonic != nil
		}
	}
}
