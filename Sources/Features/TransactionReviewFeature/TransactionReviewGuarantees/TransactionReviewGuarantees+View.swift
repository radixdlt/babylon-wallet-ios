import FeaturePrelude

// MARK: - TransactionReviewGuarantees.View
extension TransactionReviewGuarantees {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				ScrollView(showsIndicators: false) {
					VStack(spacing: 0) {
						Text(L10n.TransactionReview.Guarantees.title)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)
							.padding(.vertical, .medium3)

						Button(L10n.TransactionReview.Guarantees.infoButtonText, asset: AssetResource.info) {
							ViewStore(store).send(.view(.infoTapped))
						}
						.textStyle(.body1Header)
						.foregroundColor(.app.blue2)
						.padding(.horizontal, .large2)
						.padding(.bottom, .medium1)

						Text(L10n.TransactionReview.Guarantees.headerText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.foregroundColor(.app.gray1)
							.padding(.horizontal, .large2)
							.padding(.bottom, .medium1)
					}
					.frame(maxWidth: .infinity)

					VStack(spacing: .medium2) {
						ForEachStore(
							store.scope(
								state: \.guarantees,
								action: { .child(.guarantee(id: $0, action: $1)) }
							),
							content: { TransactionReviewGuarantee.View(store: $0) }
						)
					}
					.padding(.medium1)
					.background(.app.gray5)
				}
				.safeAreaInset(edge: .bottom, spacing: .zero) {
					ConfirmationFooter(
						title: L10n.TransactionReview.Guarantees.applyButtonText,
						isEnabled: true,
						action: { ViewStore(store).send(.view(.applyTapped)) }
					)
				}
				.sheet(store: store.scope(state: \.$info, action: { .child(.info($0)) })) {
					SlideUpPanel.View(store: $0)
						.presentationDetents([.medium])
						.presentationDragIndicator(.visible)
					#if os(iOS)
						.presentationBackground(.blur)
					#endif
				}
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							ViewStore(store).send(.view(.closeTapped))
						}
					}
				}
			}
		}
	}
}

extension TransactionReviewGuarantee.State {
	var viewState: TransactionReviewGuarantee.ViewState {
		.init(id: id, account: account, token: .init(transfer: transfer))
	}
}

extension TransactionReviewTokenView.ViewState {
	init(transfer: TransactionReview.Transfer) {
		self.init(name: transfer.metadata.name,
		          thumbnail: transfer.metadata.thumbnail,
		          amount: transfer.action.amount,
		          guaranteedAmount: transfer.guarantee?.amount,
		          fiatAmount: transfer.metadata.fiatAmount)
	}
}

extension TransactionReviewGuarantee {
	public struct ViewState: Identifiable, Equatable {
		public let id: AccountAction
		let account: TransactionReview.Account
		let token: TransactionReviewTokenView.ViewState
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<TransactionReviewGuarantee>

		public init(store: StoreOf<TransactionReviewGuarantee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Card(verticalSpacing: 0) {
					AccountLabel(account: viewStore.account) {
						viewStore.send(.copyAddressTapped)
					}

					TransactionReviewTokenView(viewState: viewStore.token)

					Separator()

					HStack(spacing: .medium3) {
						Text(L10n.TransactionReview.Guarantees.setText)
							.lineLimit(2)
							.textStyle(.body2Header)
							.foregroundColor(.app.gray1)

						Spacer(minLength: 0)

						let stepperStore = store.scope(state: \.percentageStepper) { .child(.percentageStepper($0)) }
						MinimumPercentageStepperView(store: stepperStore)
					}
					.padding(.medium3)
				}
			}
		}
	}
}

// MARK: - MinimumPercentageStepperView
public struct MinimumPercentageStepperView: View {
	public let store: StoreOf<MinimumPercentageStepper>

	public init(store: StoreOf<MinimumPercentageStepper>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			HStack(spacing: .medium3) {
				Button(asset: AssetResource.minusCircle) {
					viewStore.send(.decreaseTapped)
				}
				.opacity(viewStore.disableMinus ? 0.2 : 1)
				.disabled(viewStore.disableMinus)

				Text("\(viewStore.value, specifier: "%.1f")")
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray1)

				Button(asset: AssetResource.plusCircle) {
					viewStore.send(.increaseTapped)
				}
				.opacity(viewStore.disablePlus ? 0.2 : 1)
				.disabled(viewStore.disablePlus)
			}
		}
	}
}

extension MinimumPercentageStepper.State {
	var disablePlus: Bool {
		value >= 100
	}

	var disableMinus: Bool {
		value <= 0
	}
}

// MARK: - MinimumPercentageStepper
public struct MinimumPercentageStepper: ReducerProtocol {
	public struct State: Sendable, Hashable {
		public var value: Double
		var precision: Int = 3

		public init(value: Double) {
			self.value = value
		}
	}

	public enum Action: Sendable, Equatable {
		case increaseTapped
		case decreaseTapped
	}

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .increaseTapped:
			state.updateMinimumPercentage(with: state.value + percentageDelta)
			return .none

		case .decreaseTapped:
			state.updateMinimumPercentage(with: state.value - percentageDelta)
			return .none
		}
	}

	private let percentageDelta: Double = 0.1
}

extension MinimumPercentageStepper.State {
	mutating func updateMinimumPercentage(with newPercentage: Double) {
		value = max(min(newPercentage, 100), 0)
	}
}
