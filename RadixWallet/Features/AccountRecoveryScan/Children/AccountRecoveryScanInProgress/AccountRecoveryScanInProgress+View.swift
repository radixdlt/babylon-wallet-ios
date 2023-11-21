extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init(
			active: active,
			hasFoundAnyAccounts: !active.isEmpty || !inactive.isEmpty
		)
	}
}

// MARK: - AccountRecoveryScanInProgress.View
public let accRecScanBatchSizePerReq = 25
public let accRecScanBatchSize = accRecScanBatchSizePerReq * 2
public extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		let active: IdentifiedArrayOf<Profile.Network.Account>
		let hasFoundAnyAccounts: Bool
		var title: String {
			hasFoundAnyAccounts ? "Scan Complete" : "Scan in progress"
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanInProgress>

		public init(store: StoreOf<AccountRecoveryScanInProgress>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text(viewStore.title)

					if viewStore.active.isEmpty {
						Text("Scanning for Accounst that have been included in at least on transaction, using:")
						Text("Babylon Seed Phrase")
					} else {
						VStack(alignment: .leading, spacing: .small3) {
							ForEach(viewStore.active) { account in
								SmallAccountCard(account: account)
									.cornerRadius(.small1)
							}
						}
						Text("The first \(accRecScanBatchSize) potential accounts from this signing factor were scanned.")

						Button("Tap here to scan the next \(accRecScanBatchSize)") {
							store.send(.view(.scanMore))
						}.buttonStyle(.secondaryRectangular)
					}
				}
				.padding()
				.footer {
					Button("Continue") {
						store.send(.view(.continueTapped))
					}.buttonStyle(.secondaryRectangular)
				}
				.onAppear {
					store.send(.view(.appear))
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AccountRecoveryScanStart_Preview

struct AccountRecoveryScanStart_Preview: PreviewProvider {
	static var previews: some View {
		AccountRecoveryScanInProgress.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountRecoveryScanInProgress.init
			)
		)
	}
}

public extension AccountRecoveryScanInProgress.State {
	static let previewValue = Self()
}
#endif
