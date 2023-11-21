extension RecoverWalletWithoutProfileStart.State {
	var viewState: RecoverWalletWithoutProfileStart.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletWithoutProfileStart.View
extension RecoverWalletWithoutProfileStart {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletWithoutProfileStart>

		public init(store: StoreOf<RecoverWalletWithoutProfileStart>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
					ScrollView {
						VStack(alignment: .center, spacing: .large3) {
							Text("Recover Control Without Backup")
								.textStyle(.sheetTitle)

							Text("If you have no wallet backup in the cloud or as an exported backup file, you still have other restore options.")
								.multilineTextAlignment(.leading)

							Divider()

							Text("**I have my main “Babylon” 24-word seed phrase.**")

							Button("Recover with Main Seed Phrase") {
								store.send(.view(.recoverWithBDFSTapped))
							}
							.buttonStyle(.secondaryRectangular)

							Divider()

							Text("**I only want to restore Ledger hardware wallet Accounts**")

							Text("OR")

							Text("**I only have Accounts created on the Radix Olympia Network**")

							Button("Ledger-only or Olmypia-only Restore") {
								store.send(.view(.ledgerOnlyOrOlympiaOnlyTapped))
							}
							.buttonStyle(.secondaryRectangular)
						}
						.multilineTextAlignment(.center)
						.padding()
					}
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton {
								store.send(.view(.closeTapped))
							}
						}
					}
					.destinations(with: store)
				}
			}
		}
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<RecoverWalletWithoutProfileStart>) -> some View {
		let destinationStore = store.destination
		return self
			.recoverWithBDFSOnly(with: destinationStore)
			.ledgerOrOlympiaOnlyAlert(with: destinationStore)
	}

	private func recoverWithBDFSOnly(
		with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfileStart.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /RecoverWalletWithoutProfileStart.Destination.State.recoverWithBDFSOnly,
			action: RecoverWalletWithoutProfileStart.Destination.Action.recoverWithBDFSOnly,
			destination: { RecoverWalletControlWithBDFSOnly.View(store: $0) }
		)
	}

	private func ledgerOrOlympiaOnlyAlert(
		with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfileStart.Destination>
	) -> some View {
		alert(
			store: destinationStore,
			state: /RecoverWalletWithoutProfileStart.Destination.State.ledgerOrOlympiaOnlyAlert,
			action: RecoverWalletWithoutProfileStart.Destination.Action.ledgerOrOlympiaOnlyAlert
		)
	}
}

private extension StoreOf<RecoverWalletWithoutProfileStart> {
	var destination: PresentationStoreOf<RecoverWalletWithoutProfileStart.Destination> {
		func scopeState(state: State) -> PresentationState<RecoverWalletWithoutProfileStart.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletWithoutProfile_Preview
struct RecoverWalletWithoutProfile_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletWithoutProfileStart.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletWithoutProfileStart.init
			)
		)
	}
}

extension RecoverWalletWithoutProfileStart.State {
	public static let previewValue = Self()
}
#endif
