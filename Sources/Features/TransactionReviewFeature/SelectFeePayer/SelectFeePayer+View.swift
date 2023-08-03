import EngineKit
import FeaturePrelude
import TransactionClient

extension SelectFeePayer.State {
	var viewState: SelectFeePayer.ViewState {
		.init(
			candidates: feePayerSelection.candidates.rawValue,
			fee: feePayerSelection.transactionFee.totalFee.displayedTotalFee,
			selectedPayer: feePayerSelection.selected
		)
	}
}

// MARK: - SelectFeePayer.View
extension SelectFeePayer {
	public struct ViewState: Equatable {
		let candidates: IdentifiedArrayOf<FeePayerCandidate>
		let fee: String
		var selectedPayer: FeePayerCandidate?
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
						Text("Select Fee Payer Account")
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.padding(.top, .medium3)
							.padding(.horizontal, .medium1)
							.padding(.bottom, .small2)

						Text("Please select an Account with enough XRD to pay \(viewStore.fee) fee for this transaction.")
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.padding(.horizontal, .large3)
							.padding(.bottom, .small1)

						ScrollView {
							VStack(spacing: .small1) {
								Selection(
									viewStore.binding(
										get: \.selectedPayer,
										send: { .selectedPayer($0) }
									),
									from: viewStore.candidates
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
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedPayer,
						forAction: { viewStore.send(.confirmedFeePayer($0)) }
					) { action in
						Button("Select Account", action: action)
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
		let accountAddress: AccountAddress
		let xrdBalance: BigDecimal

		init(candidate: FeePayerCandidate) {
			appearanceID = candidate.account.appearanceID
			accountName = candidate.account.displayName.rawValue
			accountAddress = candidate.account.address
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

						AddressView(.address(.account(viewState.accountAddress)), isTappable: false)
							.foregroundColor(.app.whiteTransparent)
							.textStyle(.body2HighImportance)
						Text("Balance \(viewState.xrdBalance.format(maxPlaces: 2)) XRD")
							.foregroundColor(.app.white)
							.textStyle(.body1Header)
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
