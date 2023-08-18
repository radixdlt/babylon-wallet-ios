import EngineKit
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
						Text(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.navigationTitle)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.padding(.top, .medium3)
							.padding(.horizontal, .medium1)
							.padding(.bottom, .small2)

						Text(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.subtitle(10))
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.padding(.horizontal, .large3)
							.padding(.bottom, .small1)

						Text(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.selectAccountButtonTitle)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.padding(.horizontal, .large3)

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
					.navigationTitle(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.navigationTitle)
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedPayer,
						forAction: { viewStore.send(.confirmedFeePayer($0)) }
					) { action in
						Button(L10n.TransactionReview.CustomizeNetworkFeeSheet.SelectFeePayer.selectAccountButtonTitle, action: action)
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

		init(candidate: FeePayerCandiate) {
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
