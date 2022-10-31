import ComposableArchitecture
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
			send: ImportMnemonic.Action.init
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
						send: { ViewAction.phraseOfMnemonicToImportChanged($0) }
					)
				)
				Button("Import mnemonic") {
					viewStore.send(.importMnemonicButtonTapped)
				}
				.disabled(!viewStore.canImportMnemonic)

				Button("Save imported mnemonic") {
					viewStore.send(.saveImportedMnemonicButtonTapped)
				}
				.disabled(!viewStore.canSaveImportedMnemonic)

				Button("Profile from snapshot") {
					viewStore.send(.importProfileFromSnapshotButtonTapped)
				}
				.disabled(!viewStore.canImportProfileFromSnapshot)
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

// MARK: - ImportMnemonic.View.ViewAction
public extension ImportMnemonic.View {
	enum ViewAction: Equatable {
		case goBackButtonTapped
		case importMnemonicButtonTapped
		case importProfileFromSnapshotButtonTapped
		case saveImportedMnemonicButtonTapped
		case phraseOfMnemonicToImportChanged(String)
	}
}

extension ImportMnemonic.Action {
	init(action: ImportMnemonic.View.ViewAction) {
		switch action {
		case .goBackButtonTapped:
			self = .internal(.goBack)
		case .importMnemonicButtonTapped:
			self = .internal(.importMnemonic)
		case .importProfileFromSnapshotButtonTapped:
			self = .internal(.importProfileFromSnapshot)
		case .saveImportedMnemonicButtonTapped:
			self = .internal(.saveImportedMnemonic)
		case let .phraseOfMnemonicToImportChanged(phrase):
			self = .internal(.phraseOfMnemonicToImportChanged(phrase))
		}
	}
}
