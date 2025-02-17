import ComposableArchitecture
import SwiftUI

extension View {
	var sectionHeading: some View {
		textStyle(.body1Header)
			.foregroundColor(.app.gray2)
	}

	var message: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
	}
}

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init(
			message: message.plaintext,
			viewControlState: viewControlState,
			rawManifest: displayMode.rawManifest,
			showApprovalSlider: reviewedTransaction != nil,
			canApproveTX: canApproveTX && reviewedTransaction?.feePayingValidation.wrappedValue?.isValid == true,
			sliderResetDate: sliderResetDate,
			canToggleViewMode: reviewedTransaction != nil && reviewedTransaction?.isNonConforming == false,
			viewRawManifestButtonState: reviewedTransaction?.feePayer.isSuccess == true ? .enabled : .disabled,
			proposingDappMetadata: proposingDappMetadata
		)
	}

	private var viewControlState: ControlState {
		if reviewedTransaction == nil {
			.loading(.global(text: L10n.TransactionSigning.preparingTransaction))
		} else {
			.enabled
		}
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	struct ViewState: Equatable {
		let message: String?

		let viewControlState: ControlState
		let rawManifest: String?
		let showApprovalSlider: Bool
		let canApproveTX: Bool
		let sliderResetDate: Date
		let canToggleViewMode: Bool
		let viewRawManifestButtonState: ControlState
		let proposingDappMetadata: DappMetadata.Ledger?

		var approvalSliderControlState: ControlState {
			// TODO: Is this the logic we want?
			canApproveTX ? viewControlState : .disabled
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		@SwiftUI.State private var showNavigationTitle: Bool = false

		private let store: StoreOf<TransactionReview>

		private let coordSpace: String = "TransactionReviewCoordSpace"
		private let navTitleID: String = "TransactionReview.title"
		private let showTitleHysteresis: CGFloat = .small3

		private let shadowColor: Color = .app.gray2.opacity(0.4)

		init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				coreView(with: viewStore)
					.controlState(viewStore.viewControlState)
					.background(.white)
					.toolbar {
						ToolbarItem(placement: .automatic) {
							if viewStore.canToggleViewMode {
								Button(asset: AssetResource.iconTxnBlocks) {
									viewStore.send(.showRawTransactionTapped)
								}
								.controlState(viewStore.viewRawManifestButtonState)
								.buttonStyle(.secondaryRectangular(isInToolbar: true))
								.brightness(viewStore.rawManifest == nil ? 0 : -0.15)
							}
						}

						ToolbarItem(placement: .principal) {
							if showNavigationTitle {
								VStack(spacing: 0) {
									Text(L10n.TransactionReview.title)
										.textStyle(.body2Header)
										.foregroundColor(.app.gray1)

									if let name = viewStore.proposingDappMetadata?.name {
										Text(L10n.InteractionReview.subtitle(name.rawValue))
											.textStyle(.body2Regular)
											.foregroundColor(.app.gray2)
									}
								}
							}
						}
					}
					.destinations(with: store)
					.onAppear {
						viewStore.send(.appeared)
					}
			}
		}

		@ViewBuilder
		private func coreView(with viewStore: ViewStoreOf<TransactionReview>) -> some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					header(viewStore.proposingDappMetadata)

					if let manifest = viewStore.rawManifest {
						Common.RawManifestView(manifest: manifest)
					} else {
						VStack(spacing: .medium1) {
							messageSection(with: viewStore.message)

							sections
						}
						.padding(.top, .small1)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .large1)
					}

					VStack(spacing: .medium1) {
						proofsSection

						feeSection

						if viewStore.showApprovalSlider {
							ApprovalSlider(
								title: L10n.TransactionReview.slideToSign,
								resetDate: viewStore.sliderResetDate
							) {
								viewStore.send(.approvalSliderSlid)
							}
							.controlState(viewStore.approvalSliderControlState)
							.padding(.horizontal, .small3)
						}
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, .large3)
					.padding(.horizontal, .large2)
					.background {
						JaggedEdge(shadowColor: shadowColor, isTopEdge: false)
					}
				}
				.background(Common.gradientBackground)
				.animation(.easeInOut, value: viewStore.canToggleViewMode ? viewStore.rawManifest : nil)
			}
			.coordinateSpace(name: coordSpace)
			.onPreferenceChange(PositionsPreferenceKey.self) { positions in
				guard let offset = positions[navTitleID]?.maxY else {
					showNavigationTitle = true
					return
				}
				if showNavigationTitle, offset > showTitleHysteresis {
					showNavigationTitle = false
				} else if !showNavigationTitle, offset < 0 {
					showNavigationTitle = true
				}
			}
		}

		private func header(_ proposingDappMetadata: DappMetadata.Ledger?) -> some SwiftUI.View {
			Common.HeaderView(
				kind: .transaction,
				name: proposingDappMetadata?.name?.rawValue,
				thumbnail: proposingDappMetadata?.thumbnail
			)
			.measurePosition(navTitleID, coordSpace: coordSpace)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium3)
			.background {
				JaggedEdge(shadowColor: shadowColor, isTopEdge: true)
			}
		}

		@ViewBuilder
		private func messageSection(with message: String?) -> some SwiftUI.View {
			if let message {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.message
					TransactionMessageView(message: message)
				}
			}
		}

		private var sections: some SwiftUI.View {
			let childStore = store.scope(state: \.sections, action: \.child.sections)
			return Common.Sections.View(store: childStore)
		}

		private var proofsSection: some SwiftUI.View {
			let proofsStore = store.scope(state: \.proofs) { .child(.proofs($0)) }
			return IfLetStore(proofsStore) { childStore in
				Common.Proofs.View(store: childStore)
			}
		}

		private var feeSection: some SwiftUI.View {
			let feeStore = store.scope(state: \.networkFee) { .child(.networkFee($0)) }
			return IfLetStore(feeStore) { childStore in
				TransactionReviewNetworkFee.View(store: childStore)
			}
		}
	}
}

extension StoreOf<TransactionReview> {
	var destination: PresentationStoreOf<TransactionReview.Destination> {
		func scopeState(state: State) -> PresentationState<TransactionReview.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<TransactionReview>) -> some View {
		let destinationStore = store.destination
		return customizeGuarantees(with: destinationStore)
			.customizeFees(with: destinationStore)
			.submitting(with: destinationStore)
			.rawTransactionAlert(with: destinationStore)
	}

	private func customizeGuarantees(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.customizeGuarantees,
			action: TransactionReview.Destination.Action.customizeGuarantees,
			content: { TransactionReviewGuarantees.View(store: $0) }
		)
	}

	private func customizeFees(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.customizeFees,
			action: TransactionReview.Destination.Action.customizeFees,
			content: { CustomizeFees.View(store: $0).inNavigationView }
		)
	}

	private func submitting(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /TransactionReview.Destination.State.submitting,
			action: TransactionReview.Destination.Action.submitting,
			content: { SubmitTransaction.View(store: $0) }
		)
	}

	private func rawTransactionAlert(with destinationStore: PresentationStoreOf<TransactionReview.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.rawTransactionAlert, action: \.rawTransactionAlert))
	}
}

// MARK: - TransactionMessageView
struct TransactionMessageView: View {
	let message: String

	var body: some View {
		Speechbubble {
			Text(message)
				.message
				.flushedLeft
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct TransactionReview_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		TransactionReview.View(
			store: .init(initialState: .previewValue) {
				TransactionReview()
			}
		)
	}
}

extension TransactionReview.State {
	static let previewValue: Self = .init(
		unvalidatedManifest: .sample,
		nonce: .secureRandom(),
		signTransactionPurpose: .manifestFromDapp,
		message: .none,
		interactionId: .walletInteractionID(for: .accountTransfer),
		proposingDappMetadata: nil,
		p2pRoute: .wallet
	)
}
#endif
