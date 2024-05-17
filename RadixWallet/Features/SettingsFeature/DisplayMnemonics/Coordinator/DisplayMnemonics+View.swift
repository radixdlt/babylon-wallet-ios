import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonics.View
extension DisplayMnemonics {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonics>

		public init(store: StoreOf<DisplayMnemonics>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .medium1) {
						Text(L10n.SeedPhrases.message)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.leading)
							.padding(.horizontal, .medium3)

						WarningErrorView(text: L10n.SeedPhrases.warning, type: .warning)
							.padding(.horizontal, .medium3)

						ForEachStore(
							store.scope(
								state: \.deviceFactorSources,
								action: { .child(.row(id: $0, action: $1)) }
							)
						) { store in
							VStack(spacing: .small2) {
								DisplayEntitiesControlledByMnemonic.View(store: store)
								Separator()
							}
							.padding([.top, .horizontal], .medium3)
						}
						.background(.app.background)
					}
					.padding(.top, .medium3)
				}
				.background(.app.gray5)
				.navigationTitle(L10n.SeedPhrases.title)
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<DisplayMnemonics> {
	var destination: PresentationStoreOf<DisplayMnemonics.Destination> {
		func scopeState(state: State) -> PresentationState<DisplayMnemonics.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DisplayMnemonics>) -> some View {
		let destinationStore = store.destination
		return displayMnemonicSheet(with: destinationStore)
			.importMnemonicsSheet(with: destinationStore)
	}

	private func displayMnemonicSheet(with destinationStore: PresentationStoreOf<DisplayMnemonics.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DisplayMnemonics.Destination.State.displayMnemonic,
			action: DisplayMnemonics.Destination.Action.displayMnemonic,
			destination: { DisplayMnemonic.View(store: $0) }
		)
	}

	private func importMnemonicsSheet(with destinationStore: PresentationStoreOf<DisplayMnemonics.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DisplayMnemonics.Destination.State.importMnemonics,
			action: DisplayMnemonics.Destination.Action.importMnemonics,
			destination: { ImportMnemonicsFlowCoordinator.View(store: $0).inNavigationView }
		)
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonics_Preview
struct DisplayMnemonics_Preview: PreviewProvider {
	static var previews: some View {
		DisplayMnemonics.View(
			store: .init(
				initialState: .previewValue,
				reducer: DisplayMnemonics.init
			)
		)
	}
}

extension DisplayMnemonics.State {
	public static let previewValue = Self()
}
#endif
