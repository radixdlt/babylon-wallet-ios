#if DEBUG

extension DebugKeychainContents.State {
	var viewState: DebugKeychainContents.ViewState {
		.init(keyedMnemonics: keyedMnemonics.elements)
	}
}

// MARK: - DebugKeychainContents.View
extension DebugKeychainContents {
	public struct ViewState: Equatable {
		let keyedMnemonics: [KeyedMnemonicWithMetadata]
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugKeychainContents>

		public init(store: StoreOf<DebugKeychainContents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading) {
					Form {
						ForEach(viewStore.keyedMnemonics, id: \.self) { keyedMnemonic in
							KeyedMnemonicView(keyedMnemonic) {
								viewStore.send(.deleteMnemonicByFactorSourceID(keyedMnemonic.id))
							}
						}
					}
					Button("Delete All") {
						viewStore.send(.deleteAllMnemonics)
					}
					.padding()
					.buttonStyle(.primaryRectangular(isDestructive: true))
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}

struct KeyedMnemonicView: SwiftUI.View {
	let keyedMnemonicWithMetadata: KeyedMnemonicWithMetadata
	var keyedMnemonicWithPassphrase: KeyedMnemonicWithPassphrase { keyedMnemonicWithMetadata.keyedMnemonic }
	let delete: @Sendable () -> Void

	init(_ keyedMnemonicWithMetadata: KeyedMnemonicWithMetadata, delete: @escaping @Sendable () -> Void) {
		self.keyedMnemonicWithMetadata = keyedMnemonicWithMetadata
		self.delete = delete
	}

	var body: some SwiftUI.View {
		VStack {
			Text("`\(keyedMnemonicWithPassphrase.factorSourceID.description)`")
				.textStyle(.body3HighImportance)

			if let entitiesControlledByFactorSource = keyedMnemonicWithMetadata.entitiesControlledByFactorSource {
				VStack(alignment: .leading, spacing: .small3) {
					ForEach(entitiesControlledByFactorSource.accounts) { account in
						AccountCard(account: account)
					}
				}
			} else {
				Text("❌ Unknown by current Profile")
			}

			Text("*\(keyedMnemonicWithPassphrase.mnemonicWithPassphrase.mnemonic.phrase)*")
			Button("Delete") {
				delete()
			}
			.padding()
			.buttonStyle(.primaryRectangular(isDestructive: true))
		}
	}
}

#endif // DEBUG
