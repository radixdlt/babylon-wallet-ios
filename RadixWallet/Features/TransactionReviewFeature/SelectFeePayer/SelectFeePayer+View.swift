import ComposableArchitecture
import SwiftUI

extension SelectFeePayer.State {
	var viewState: SelectFeePayer.ViewState {
		.init(
			feePayerCandidates: feePayerCandidates.rawValue,
			fee: transactionFee.totalFee.displayedTotalFee,
			selectedPayer: feePayer
		)
	}
}

// MARK: - SelectFeePayer.View
extension SelectFeePayer {
	public struct ViewState: Equatable {
		let feePayerCandidates: Loadable<IdentifiedArrayOf<FeePayerCandidate>>
		let fee: String
		let selectedPayer: FeePayerCandidate?

		var selectButtonControlState: ControlState {
			switch feePayerCandidates {
			case .idle, .loading:
				.loading(.local)
			case .success:
				.enabled
			case .failure:
				.disabled
			}
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
					Text(L10n.CustomizeNetworkFees.SelectFeePayer.navigationTitle)
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.horizontal, .medium1)
						.padding(.bottom, .small2)

					Text(L10n.CustomizeNetworkFees.SelectFeePayer.subtitle(viewStore.fee))
						.multilineTextAlignment(.center)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray2)
						.padding(.horizontal, .large3)
						.padding(.bottom, .small1)

					ScrollViewReader { proxy in
						ScrollView {
							loadable(viewStore.feePayerCandidates) {
								ProgressView()
							} successContent: { candidates in
								VStack(spacing: .small1) {
									Selection(
										viewStore.binding(
											get: \.selectedPayer,
											send: { .selectedPayer($0) }
										),
										from: candidates
									) { item in
										SelectAccountToPayForFeeRow.View(
											viewState: .init(candidate: item.value),
											isSelected: item.isSelected,
											action: item.action
										)
										.id(item.value.id)
									}
								}
								.padding(.horizontal, .medium1)
								.padding(.bottom, .medium2)
								.onFirstAppear {
									proxy.scrollTo(viewStore.selectedPayer?.id, anchor: .center)
								}
							}
						}
					}
					.refreshable { @MainActor in
						await viewStore.send(.pullToRefreshStarted).finish()
					}
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
				.footer {
					WithControlRequirements(
						viewStore.selectedPayer,
						forAction: { viewStore.send(.confirmedFeePayer($0)) }
					) { action in
						Button(L10n.CustomizeNetworkFees.SelectFeePayer.selectAccountButtonTitle, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(viewStore.selectButtonControlState)
					}
				}
				.withNavigationBar {
					store.send(.view(.closeButtonTapped))
				}
			}
		}
	}
}

// MARK: - SelectAccountToPayForFeeRow
enum SelectAccountToPayForFeeRow {
	struct ViewState: Equatable {
		let account: Account
		let fungible: ResourceBalance.ViewState.Fungible

		init(candidate: FeePayerCandidate) {
			self.account = candidate.account
			self.fungible = .xrd(balance: .init(nominalAmount: candidate.xrdBalance), network: account.networkID)
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
					VStack(spacing: .zero) {
						AccountCard(kind: .innerCompact, account: viewState.account)

						HStack {
							ResourceBalanceView(.fungible(viewState.fungible), appearance: .compact)

							RadioButton(appearance: .dark, state: isSelected ? .selected : .unselected)
						}
						.padding(.medium3)
					}
				}
			}
			.buttonStyle(.inert)
		}
	}
}
