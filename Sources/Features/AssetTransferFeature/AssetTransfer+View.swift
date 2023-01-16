import FeaturePrelude

// MARK: - AssetTransfer.View
public extension AssetTransfer {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension AssetTransfer.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			NavigationView {
				Form {
					VStack(alignment: .leading) {
						Text("From")
						AddressView(viewStore.fromAddress)
							.foregroundColor(.gray)
					}

					TextField(
						"XRD amount",
						text: viewStore.binding(
							get: \.amount,
							send: { .amountTextFieldChanged($0) }
						),
						prompt: Text("Enter amount...")
					)
					.keyboardType(.numberPad)

					VStack(alignment: .leading) {
						Text("To")
						TextField(
							"To address",
							text: viewStore.binding(
								get: \.toAddress,
								send: { .toAddressTextFieldChanged($0) }
							),
							prompt: Text("Enter address...")
						)
					}
				}
				.navigationTitle(Text("Send XRD"))
				.navigationBarTitleDisplayMode(.large)
			}
			.navigationViewStyle(.stack)
		}
	}
}

// MARK: - AssetTransfer.View.ViewState
extension AssetTransfer.View {
	// MARK: ViewState

	struct ViewState: Equatable {
		var fromAddress: AddressView.ViewState
		var amount: String
		var toAddress: String

		init(state: AssetTransfer.State) {
			self.fromAddress = .init(
				address: state.from.address.address,
				format: .short()
			)
			self.amount = state.amount?.value ?? ""
			switch state.to {
			case let .address(address):
				self.toAddress = address.address
			case nil:
				self.toAddress = ""
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AssetTransfer_Preview: PreviewProvider {
	static var previews: some View {
		AssetTransfer.View(
			store: .init(
				initialState: .init(
					from: .previewValue0
				),
				reducer: AssetTransfer()
			)
		)
	}
}
#endif
