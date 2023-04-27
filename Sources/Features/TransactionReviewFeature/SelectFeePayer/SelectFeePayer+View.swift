import FeaturePrelude
import TransactionClient

extension SelectFeePayer.State {
	var viewState: SelectFeePayer.ViewState {
		.init(candidates: feePayerCandidates.rawValue, selectedPayerID: selectedPayerID, fee: fee)
	}
}

// MARK: - SelectFeePayer.View
extension SelectFeePayer {
	public struct ViewState: Equatable {
		let candidates: IdentifiedArrayOf<FeePayerCandiate>
		let selectedPayerID: FeePayerCandiate.ID?
		let fee: BigDecimal
		var selectedPayer: FeePayerCandiate? {
			guard let id = selectedPayerID else {
				return nil
			}
			return candidates[id: id]
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectFeePayer>

		public init(store: StoreOf<SelectFeePayer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					VStack {
						Text("The transaction you are about to sign does not reference and your accounts so you must chose which account you would like to pay the transaction fee with.")
						Spacer()
						Text("Select account to pay \(viewStore.fee.format()) tx fee.")

						Picker(
							"Fee payer",
							selection: viewStore.binding(
								get: \.selectedPayerID,
								send: { .selectedPayer(id: $0) }
							)
						) {
							ForEach(viewStore.candidates, id: \.self) { candidate in
								Text("\(candidate.account.address.address.formatted(AddressFormat.default))")
									.tag(candidate.id)
							}
						}
					}
					.padding(.horizontal, .small1)
					.navigationTitle("Select Fee Payer")
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedPayer,
						forAction: { viewStore.send(.confirmedFeePayer($0)) }
					) { action in
						Button("Confirm fee payer", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

//
// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SelectFeePayer_Preview
// struct SelectFeePayer_Preview: PreviewProvider {
//    static var previews: some View {
//        SelectFeePayer.View(
//            store: .init(
//                initialState: .previewValue,
//                reducer: SelectFeePayer()
//            )
//        )
//    }
// }
//
// extension SelectFeePayer.State {
//    public static let previewValue = Self()
// }
// #endif
