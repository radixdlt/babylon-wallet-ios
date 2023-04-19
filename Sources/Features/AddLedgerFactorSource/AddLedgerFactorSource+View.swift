import FeaturePrelude
import NewConnectionFeature

extension AddLedgerFactorSource.State {
	var viewState: AddLedgerFactorSource.ViewState {
		.init(
			failedToFindAnyLinks: failedToFindAnyLinks,
			ledgerName: ledgerName,
			isLedgerNameInputVisible: isLedgerNameInputVisible,
			viewControlState: isWaitingForResponseFromLedger ? .loading(.global(text: "Waiting for ledger response")) : .enabled
		)
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	public struct ViewState: Equatable {
		public let failedToFindAnyLinks: Bool
		public let ledgerName: String
		public let isLedgerNameInputVisible: Bool
		public let viewControlState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddLedgerFactorSource>

		public init(store: StoreOf<AddLedgerFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					if viewStore.failedToFindAnyLinks {
						Text("⚠️ Found no open RadixConnect connections.")

						Button("Add New P2P Link") {
							viewStore.send(.addNewP2PLinkButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}

					Spacer()

					if viewStore.isLedgerNameInputVisible {
						VStack {
							nameLedgerField(with: viewStore)

							Button("Confirm name") {
								viewStore.send(.confirmNameButtonTapped)
							}
							.buttonStyle(.primaryRectangular)

							Button("Skip name") {
								viewStore.send(.skipNamingLedgerButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))
						}
					} else {
						Button("Send Add Ledger Request") {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.viewControlState)
						.buttonStyle(.primaryRectangular)
					}
				}
				.padding(.horizontal, .medium3)
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
				.sheet(
					store: store.scope(
						state: \.$addNewP2PLink,
						action: { .child(.addNewP2PLink($0)) }
					),
					content: { NewConnection.View(store: $0) }
				)
			}
		}

		@ViewBuilder
		private func nameLedgerField(with viewStore: ViewStoreOf<AddLedgerFactorSource>) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: "Name this Ledger",
				secondaryHeading: "e.g. 'scratch'",
				placeholder: "scratched",
				text: .init(
					get: { viewStore.ledgerName },
					set: { viewStore.send(.ledgerNameChanged($0)) }
				),
				hint: .info("Displayed when you are prompted to sign with this.")
			)
			.padding()
		}
	}
}
