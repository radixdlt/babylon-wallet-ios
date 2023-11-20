extension RecoverWalletWithoutProfile.State {
	var viewState: RecoverWalletWithoutProfile.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletWithoutProfile.View
extension RecoverWalletWithoutProfile {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletWithoutProfile>

		public init(store: StoreOf<RecoverWalletWithoutProfile>) {
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
	func destinations(with store: StoreOf<RecoverWalletWithoutProfile>) -> some View {
		let destinationStore = store.destination
		return self
			.recoverWithBDFSOnly(with: destinationStore)
			.ledgerOrOlympiaOnlyAlert(with: destinationStore)
	}

	private func recoverWithBDFSOnly(
		with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfile.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /RecoverWalletWithoutProfile.Destination.State.recoverWithBDFSOnly,
			action: RecoverWalletWithoutProfile.Destination.Action.recoverWithBDFSOnly,
			destination: { RecoverWalletControlWithBDFSOnly.View(store: $0) }
		)
	}

	private func ledgerOrOlympiaOnlyAlert(
		with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfile.Destination>
	) -> some View {
		alert(
			store: destinationStore,
			state: /RecoverWalletWithoutProfile.Destination.State.ledgerOrOlympiaOnlyAlert,
			action: RecoverWalletWithoutProfile.Destination.Action.ledgerOrOlympiaOnlyAlert
		)
	}
}

private extension StoreOf<RecoverWalletWithoutProfile> {
	var destination: PresentationStoreOf<RecoverWalletWithoutProfile.Destination> {
		func scopeState(state: State) -> PresentationState<RecoverWalletWithoutProfile.Destination.State> {
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
		RecoverWalletWithoutProfile.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletWithoutProfile.init
			)
		)
	}
}

extension RecoverWalletWithoutProfile.State {
	public static let previewValue = Self()
}
#endif
