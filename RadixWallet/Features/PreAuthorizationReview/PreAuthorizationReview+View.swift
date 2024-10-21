import SwiftUI

// MARK: - PreAuthorizationReview.View
extension PreAuthorizationReview {
	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview>

		@SwiftUI.State private var showNavigationTitle = false

		private let coordSpace: String = "PreAuthorizationReviewCoordSpace"
		private let navTitleID: String = "PreAuthorizationReview.title"
		private let showTitleHysteresis: CGFloat = .small3

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				content
					.background(.app.white)
					.toolbar {
						ToolbarItem(placement: .principal) {
							if showNavigationTitle {
								navigationTitle
							}
						}
					}
			}
		}

		private var navigationTitle: some SwiftUI.View {
			VStack(spacing: .zero) {
				Text("Review your Pre-Authorization")
					.textStyle(.body2Header)
					.foregroundColor(.app.gray1)

				if let name = store.dappName {
					Text("Proposed by \(name)")
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
			}
		}

		private var content: some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: .zero) {
					header

					Group {
						if let rawContent = store.displayMode.rawTransaction {
							rawTransaction(rawContent)
						} else {
							details
						}
					}
					.background(Common.gradientBackground)
					.clipShape(RoundedRectangle(cornerRadius: .small1))
					.padding(.horizontal, .small2)

					Spacer()
				}
				.animation(.easeInOut, value: store.displayMode.rawTransaction)
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

		private var header: some SwiftUI.View {
			Common.HeaderView(
				kind: .preAuthorization,
				name: store.dappName,
				thumbnail: nil
			)
			.measurePosition(navTitleID, coordSpace: coordSpace)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium3)
		}

		private func rawTransaction(_ content: String) -> some SwiftUI.View {
			Common.RawTransactionView(transaction: content) {
				store.send(.view(.copyRawTransactionButtonTapped))
			} toggleAction: {
				store.send(.view(.toggleDisplayModeButtonTapped))
			}
		}

		private var details: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium1) {
				Common.HeadingView.withdrawing

				VStack(alignment: .leading, spacing: .medium1) {
					Common.HeadingView.contributingToPools

					Common.HeadingView.redeemingFromPools
				}
				.frame(maxWidth: .infinity, alignment: .leading) // necessary?
				.background(alignment: .trailing) {
					if store.showTransferLine {
						Common.TransferLineView()
					}
				}
			}
			.padding(.top, .large2 + .small3)
			.padding(.horizontal, .small1)
			.padding(.bottom, .medium1)
			.overlay(alignment: .topTrailing) {
				Button(asset: AssetResource.code) {
					store.send(.view(.toggleDisplayModeButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)
				.padding(.medium3)
			}
		}
	}
}

extension PreAuthorizationReview.State {
	var showTransferLine: Bool {
		true
	}
}
