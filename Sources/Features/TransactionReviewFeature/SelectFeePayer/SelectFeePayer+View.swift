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
		var candidatesArray: [FeePayerCandiate]? { .init(candidates) }
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

						ScrollView {
							VStack(spacing: .small1) {
								Selection(
									viewStore.binding(
										get: \.candidatesArray,
										send: { .selectedPayer(id: $0?.first?.id) }
									),
									from: viewStore.candidates,
									requiring: .exactly(1)
								) { item in
									SelectAccountToPayForFeeRow.View(
										viewState: .init(candidate: item.value),
										isSelected: item.isSelected,
										action: item.action
									)
								}
							}

							.padding(.horizontal, .medium1)
							.padding(.bottom, .medium2)
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

// MARK: - SelectAccountToPayForFeeRow
enum SelectAccountToPayForFeeRow {
	struct ViewState: Equatable {
		let appearanceID: Profile.Network.Account.AppearanceID
		let accountName: String
		let accountAddress: AddressView.ViewState
		let xrdBalance: BigDecimal

		init(candidate: FeePayerCandiate) {
			appearanceID = candidate.account.appearanceID
			accountName = candidate.account.displayName.rawValue
			accountAddress = AddressView.ViewState(address: candidate.account.address.address, format: .default)
			xrdBalance = candidate.xrdBalance
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let viewState: ViewState
		let isSelected: Bool
		let action: () -> Void

		var body: some SwiftUI.View {
			Button(action: action) {
				HStack {
					VStack(alignment: .leading, spacing: .medium3) {
						Text(viewState.accountName)
							.foregroundColor(.app.white)
							.textStyle(.body1Header)

						AddressView(viewState.accountAddress, copyAddressAction: .none)
							.foregroundColor(.app.white.opacity(0.8))
							.textStyle(.body2HighImportance)
					}

					Spacer()

					RadioButton(
						appearance: .light,
						state: isSelected ? .selected : .unselected
					)
				}
				.padding(.medium1)
				.background(
					viewState.appearanceID.gradient
						.brightness(isSelected ? -0.1 : 0)
				)
				.cornerRadius(.small1)
			}
			.buttonStyle(.inert)
		}
	}
}
