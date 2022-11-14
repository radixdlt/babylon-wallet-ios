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
							Image("arrow-back")
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
				PrimaryButton(
					"Import mnemonic",
					isEnabled: viewStore.canImportMnemonic
				) {
					viewStore.send(.importMnemonicButtonTapped)
				}

				PrimaryButton(
					"Save imported mnemonic",
					isEnabled: viewStore.canSaveImportedMnemonic
				) {
					viewStore.send(.saveImportedMnemonicButtonTapped)
				}

				PrimaryButton(
					"Profile from snapshot",
					isEnabled: viewStore.canImportProfileFromSnapshot
				) {
					viewStore.send(.importProfileFromSnapshotButtonTapped)
				}
			}
		}
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
