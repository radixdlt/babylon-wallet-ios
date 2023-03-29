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

// MARK: - MinimumPercentageStepper
public struct MinimumPercentageStepper: ReducerProtocol {
	public struct State: Sendable, Hashable {
		public var value: BigDecimal
		var string: String

		var isValid: Bool {
			BigDecimal(validated: string) != nil
		}

		public init(value: BigDecimal) {
			self.value = value
			self.string = value.toString()
		}
	}

	public enum Action: Sendable, Equatable {
		case increaseTapped
		case decreaseTapped
		case stringEntered(String)
	}

	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .increaseTapped:
			let value = (state.value + percentageDelta).clamped.withScale(1)
			state.value = value
			state.string = value.toString()

			return .none

		case .decreaseTapped:
			let value = (state.value - percentageDelta).clamped.withScale(1)
			state.value = value
			state.string = value.toString()

			return .none

		case let .stringEntered(string):
			state.string = string
			if let value = BigDecimal(validated: string) {
				state.value = value
			}
			return .none
		}

		return .none
	}

	private let percentageDelta: BigDecimal = 0.1
}

extension BigDecimal {
	var clamped: BigDecimal {
		max(min(self, 100), 0)
	}

	init?(validated string: String) {
		guard let value = try? BigDecimal(fromString: string) else { return nil }
		guard value >= 0, value <= 100 else { return nil }
		self = value
	}
}

extension MinimumPercentageStepper.State {
	var validatedFromString: BigDecimal? {
		guard let value = try? BigDecimal(fromString: string) else { return nil }
		guard value >= 0, value <= 100 else { return nil }
		return value
	}

	var disablePlus: Bool {
		value >= 100
	}

	var disableMinus: Bool {
		value <= 0
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

				TextField("", text: viewStore.binding(get: \.string, send: MinimumPercentageStepper.Action.stringEntered))
					.keyboardType(.decimalPad)
					.textStyle(.body2Regular)
					.foregroundColor(viewStore.isValid ? .app.gray1 : .app.alert)

				Button(asset: AssetResource.plusCircle) {
					viewStore.send(.increaseTapped)
				}
				.opacity(viewStore.disablePlus ? 0.2 : 1)
				.disabled(viewStore.disablePlus)
			}
		}
	}
}
