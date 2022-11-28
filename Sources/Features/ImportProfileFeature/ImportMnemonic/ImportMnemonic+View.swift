import Common
import ComposableArchitecture
import DesignSystem
import Foundation
import SwiftUI

// MARK: - ImportMnemonic.View
public extension ImportMnemonic {
	@MainActor
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
					Text(L10n.ImportProfile.importMnemonic.capitalized)
					Spacer()
					EmptyView()
				}
				Spacer()

				TextField(
					L10n.ImportProfile.mnemonicPhrasec,
					text: viewStore.binding(
						get: \.phraseOfMnemonicToImport,
						send: { .phraseOfMnemonicToImportChanged($0) }
					)
				)
				Button(
					L10n.ImportProfile.importMnemonic
				) {
					viewStore.send(.importMnemonicButtonTapped)
				}
				.enabled(viewStore.canImportMnemonic)

				Button(
					L10n.ImportProfile.saveImportedMnemonic
				) {
					viewStore.send(.saveImportedMnemonicButtonTapped)
				}
				.enabled(viewStore.canSaveImportedMnemonic)

				Button(
					L10n.ImportProfile.profileFromSnapshot
				) {
					viewStore.send(.importProfileFromSnapshotButtonTapped)
				}
				.enabled(viewStore.canImportProfileFromSnapshot)
			}
		}
		.buttonStyle(.primaryRectangular)
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
