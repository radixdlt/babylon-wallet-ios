import FeaturePrelude
import TransactionSigningFeature

extension AssetTransfer.State {
	fileprivate var viewState: AssetTransfer.ViewState {
		.init(
			input: .init(
				fromAddress: .init(
					address: from.address.address,
					format: .default
				),
				amount: amount?.value ?? "",
				toAddress: to?.address.address ?? ""
			),
			output: {
				if
					let amount = amount,
					let toAddress = to?.address
				{
					return .init(amount: amount, toAddress: toAddress)
				} else {
					return nil
				}
			}()
		)
	}
}

// MARK: - AssetTransfer.View
extension AssetTransfer {
	public struct ViewState: Equatable {
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
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		public init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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
