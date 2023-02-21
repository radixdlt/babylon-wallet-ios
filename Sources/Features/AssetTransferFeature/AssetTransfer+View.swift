import FeaturePrelude
import TransactionSigningFeature

// MARK: - AssetTransfer.View
extension AssetTransfer {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			NavigationView {
				Form {
					VStack(alignment: .leading) {
						Text("From")
						AddressView(viewStore.input.fromAddress)
							.foregroundColor(.gray)
					}

					TextField(
						"XRD amount",
						text: viewStore.binding(
							get: \.input.amount,
							send: { .amountTextFieldChanged($0) }
						),
						prompt: Text("Enter amount...")
					)
					#if os(iOS)
					.keyboardType(.numberPad)
					#endif

					VStack(alignment: .leading) {
						Text("To")
						TextField(
							"To address",
							text: viewStore.binding(
								get: \.input.toAddress,
								send: { .toAddressTextFieldChanged($0) }
							),
							prompt: Text("Enter address...")
						)
					}
				}
				.navigationTitle(Text("Send XRD"))
				#if os(iOS)
					.navigationBarTitleDisplayMode(.large)
				#endif
					.safeAreaInset(edge: .bottom, spacing: .zero) {
						WithControlRequirements(
							viewStore.output,
							forAction: {
								viewStore.send(
									.nextButtonTapped(amount: $0.amount, toAddress: $0.toAddress)
								)
							}
						) { action in
							Button("Next", action: action)
								.buttonStyle(.primaryRectangular)
								.padding()
						}
					}
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /AssetTransfer.Destinations.State.transactionSigning,
						action: AssetTransfer.Destinations.Action.transactionSigning,
						content: { TransactionSigning.View(store: $0) }
					)
			}
			#if os(iOS)
			.navigationViewStyle(.stack)
			#endif
		}
	}
}

// MARK: - AssetTransfer.View.ViewState
extension AssetTransfer.View {
	// MARK: ViewState

	struct ViewState: Equatable {
		struct Input: Equatable {
			let fromAddress: AddressView.ViewState
			let amount: String
			let toAddress: String
		}

		struct Output: Equatable {
			let amount: Decimal_
			let toAddress: AccountAddress
		}

		let input: Input
		let output: Output?

		init(state: AssetTransfer.State) {
			self.input = .init(
				fromAddress: .init(
					address: state.from.address.address,
					format: .short()
				),
				amount: state.amount?.value ?? "",
				toAddress: state.to?.address.address ?? ""
			)
			self.output = {
				if
					let amount = state.amount,
					let toAddress = state.to?.address
				{
					return .init(amount: amount, toAddress: toAddress)
				} else {
					return nil
				}
			}()
		}
	}
}

// FIXME: fix post betanet v2 release
// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct AssetTransfer_Preview: PreviewProvider {
//	static var previews: some View {
//		AssetTransfer.View(
//			store: .init(
//				initialState: .init(
//					from: .previewValue0
//				),
//				reducer: AssetTransfer()
//			)
//		)
//	}
// }
// #endif
