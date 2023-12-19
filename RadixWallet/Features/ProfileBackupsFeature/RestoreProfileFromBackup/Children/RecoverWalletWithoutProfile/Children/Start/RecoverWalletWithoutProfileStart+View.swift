// MARK: - RecoverWalletWithoutProfileStart.View
extension RecoverWalletWithoutProfileStart {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletWithoutProfileStart>

		public init(store: StoreOf<RecoverWalletWithoutProfileStart>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				ScrollView {
					VStack(alignment: .center, spacing: .large3) {
						Text(L10n.RecoverWalletWithoutProfile.Start.headerTitle)
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text(LocalizedStringKey(L10n.RecoverWalletWithoutProfile.Start.headerSubtitle))
							.multilineTextAlignment(.leading)
							.textStyle(.body1Regular)
							.padding(.horizontal, .large2)

						Divider()
							.padding(.horizontal, .medium1)

						Text(L10n.RecoverWalletWithoutProfile.Start.babylonSectionTitle)
							.textStyle(.body1Header)
							.padding(.horizontal, .large2)

						Button(L10n.RecoverWalletWithoutProfile.Start.babylonSectionButton) {
							store.send(.view(.recoverWithBDFSTapped))
						}
						.padding(.horizontal, .medium3)

						Divider()
							.padding(.horizontal, .medium1)

						Text(L10n.RecoverWalletWithoutProfile.Start.hardwareSectionTitle)
							.textStyle(.body1Header)
							.padding(.horizontal, .large2)

						Button(L10n.RecoverWalletWithoutProfile.Start.hardwareSectionButton) {
							store.send(.view(.ledgerOnlyTapped))
						}
						.padding(.horizontal, .medium3)

						Divider()
							.padding(.horizontal, .medium1)

						Text(L10n.RecoverWalletWithoutProfile.Start.olympiaSectionTitle)
							.textStyle(.body1Header)
							.padding(.horizontal, .large2)

						Button(L10n.RecoverWalletWithoutProfile.Start.olympiaSectionButton) {
							store.send(.view(.olympiaOnlyTapped))
						}
						.padding(.horizontal, .medium3)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.vertical, .small1)
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

@MainActor
private extension View {
	func destinations(with store: StoreOf<RecoverWalletWithoutProfileStart>) -> some View {
		let destinationStore = store.destination
		return self
			.ledgerOrOlympiaOnlyAlert(with: destinationStore)
	}

	private func ledgerOrOlympiaOnlyAlert(
		with destinationStore: PresentationStoreOf<RecoverWalletWithoutProfileStart.Destination>
	) -> some View {
		alert(
			store: destinationStore,
			state: /RecoverWalletWithoutProfileStart.Destination.State.alert,
			action: RecoverWalletWithoutProfileStart.Destination.Action.alert
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
