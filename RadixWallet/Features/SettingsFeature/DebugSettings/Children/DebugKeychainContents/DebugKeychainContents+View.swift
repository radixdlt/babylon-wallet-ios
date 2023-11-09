#if DEBUG

extension DebugKeychainContents.State {
	var viewState: DebugKeychainContents.ViewState {
		.init(keyedMnemonics: keyedMnemonics.elements)
	}
}

// MARK: - DebugKeychainContents.View
extension DebugKeychainContents {
	public struct ViewState: Equatable {
		let keyedMnemonics: [KeyedMnemonicWithPassphrase]
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugKeychainContents>

		public init(store: StoreOf<DebugKeychainContents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(alignment: .leading) {
//						Form {
//							ForEach(viewStore.keyedMnemonics, id: \.self) { keyValue in
//								VStack(alignment: .leading) {
//									Text("`\(keyValue.id)`")
//										.textStyle(.body1Header)
//
//									MnemonicView(keyValue.mnemonicWithPasshprase) {
//										viewStore.send(.deleteMnemonicByFactorSourceID(keyValue.id))
//									}
//								}
//								.frame(maxWidth: .infinity)
//							}
//						}
						Button("Delete All") {
							viewStore.send(.deleteAllMnemonics)
						}
						.padding()
						.buttonStyle(.primaryRectangular(isDestructive: true))
					}
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}

struct MnemonicView: SwiftUI.View {
	let mnemonicWithPassphrase: MnemonicWithPassphrase
	let delete: @Sendable () -> Void
	init(_ mnemonicWithPassphrase: MnemonicWithPassphrase, delete: @escaping @Sendable () -> Void) {
		self.mnemonicWithPassphrase = mnemonicWithPassphrase
		self.delete = delete
	}

	var body: some SwiftUI.View {
		VStack {
			Text("**\(mnemonicWithPassphrase.mnemonic.phrase.rawValue)**")
			Button("Delete") {
				delete()
			}
		}
	}
}

#endif // DEBUG
