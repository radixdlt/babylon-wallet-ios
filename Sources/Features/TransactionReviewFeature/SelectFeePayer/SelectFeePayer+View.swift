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
					Text(L10n.TransactionReview.SelectFeePayer.navigationTitle)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.top, .medium3)
						.padding(.horizontal, .medium1)
						.padding(.bottom, .small2)
						.multilineTextAlignment(.center)

					Text(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.subtitle(fee))
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray2)
						.padding(.horizontal, .large3)
						.padding(.bottom, .small1)
						.multilineTextAlignment(.center)

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
				.footer {
					WithControlRequirements(
						viewStore.selectedPayer,
						forAction: { viewStore.send(.confirmedFeePayer($0)) }
					) { action in
						Button(L10n.TransactionReview.CustomizeNetworkFeeSheet.selectFeePayerButtonTitle, action: action)
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
		let account: Profile.Network.Account
		let xrdBalance: BigDecimal

		init(candidate: FeePayerCandidate) {
			account = candidate.account
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
				Card {
					VStack(spacing: 0) {
						SmallAccountCard(account: viewState.account)
						HStack {
							TokenBalanceView(viewState: .init(thumbnail: .xrd, name: "XRD", balance: viewState.xrdBalance))
							RadioButton(
								appearance: .dark,
								state: isSelected ? .selected : .unselected
							)
						}
						.padding(.medium3)
					}
				}
			}
			.buttonStyle(.inert)
		}
	}
}
