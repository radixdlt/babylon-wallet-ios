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
					.onAppear {
						store.send(.view(.appeared))
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

					feesInformation
						.padding(.top, .small2)
						.padding(.horizontal, .small2)

					expiration

					slider
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
				thumbnail: store.dappThumbnail
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
				withdrawals

				VStack(alignment: .leading, spacing: .medium1) {
					deposits
				}
				.frame(maxWidth: .infinity, alignment: .leading) // necessary?
				.background(alignment: .trailing) {
					if store.showTransferLine {
						Common.TransferLineView()
					}
				}

				proofs
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

		@ViewBuilder
		private var withdrawals: some SwiftUI.View {
			if let childStore = store.scope(state: \.withdrawals, action: \.child.withdrawals) {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.withdrawing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private var deposits: some SwiftUI.View {
			if let childStore = store.scope(state: \.deposits, action: \.child.deposits) {
				VStack(alignment: .leading, spacing: .small2) {
					Common.HeadingView.depositing
					Common.Accounts.View(store: childStore)
				}
			}
		}

		@ViewBuilder
		private var proofs: some SwiftUI.View {
			if let childStore = store.scope(state: \.proofs, action: \.child.proofs) {
				Common.Proofs.View(store: childStore)
					.padding(.horizontal, .small3)
			}
		}

		private var feesInformation: some SwiftUI.View {
			HStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .zero) {
					Text("Pre-authorization will be returned to \(store.dappName ?? "dApp") for processing.")
						.foregroundStyle(.app.gray1)

					Text("Network fees will be paid by the dApp")
						.foregroundStyle(.app.gray2)
				}
				.textStyle(.body2Regular)

				Spacer(minLength: .small2)

				InfoButton(.dapps) // TODO: Update to correct one
			}
			.padding(.vertical, .medium3)
			.padding(.horizontal, .medium2)
			.background(Color.app.gray5)
			.clipShape(RoundedRectangle(cornerRadius: .small1))
		}

		private var expiration: some SwiftUI.View {
			Group {
				switch store.expiration {
				case .none:
					Color.clear
				case let .window(seconds):
					let value = formatTime(seconds: seconds)
					Text("Valid for **\(value) after approval**")
				case .atTime:
					if let seconds = store.secondsToExpiration {
						if seconds > 0 {
							let value = formatTime(seconds: seconds)
							Text("Valid for the next **\(value)**")
						} else {
							Text("This subintent is no longer valid!")
						}
					}
				}
			}
			.textStyle(.body2Regular)
			.foregroundStyle(.app.account4pink)
			.padding(.horizontal, .medium1)
			.frame(minHeight: .huge2)
		}

		private var slider: some SwiftUI.View {
			ApprovalSlider(
				title: "Slide to sign and return",
				resetDate: store.sliderResetDate
			) {}
				.controlState(store.sliderControlState)
				.padding(.horizontal, .medium2)
		}
	}
}

private extension PreAuthorizationReview.View {
	/// Given an amount of seconds, returns a formatted String using the corresponding unit (days/hours/minutes/seconds).
	/// A few examples on how should it look for each of them:
	/// - `8 days` / `1 day`
	/// - `23:21 hours` / `1:24 hour`
	/// - `56:02 minutes` / `1:23 minute`
	/// - `34 seconds` / `1 second`
	func formatTime(seconds: Int) -> String {
		let minutes = seconds / 60
		let hours = minutes / 60
		let days = hours / 24
		if days > 0 {
			return days == 1 ? "1 day" : "\(days) days"
		} else if hours > 0 {
			let remainingMinutes = minutes % 60
			let formatted = String(format: "%d:%02d", hours, remainingMinutes)
			return hours == 1 ? "\(formatted) hour" : "\(formatted) hours"
		} else if minutes > 0 {
			let remainingSeconds = seconds % 60
			let formatted = String(format: "%d:%02d", minutes, remainingSeconds)
			return minutes == 1 ? "\(formatted) minute" : "\(formatted) minutes"
		} else {
			return seconds == 1 ? "1 second" : "\(seconds) seconds"
		}
	}
}

private extension PreAuthorizationReview.State {
	var showTransferLine: Bool {
		true
	}

	var controlState: ControlState {
		// If is loading transaction show loading
		.enabled
	}

	var sliderControlState: ControlState {
		isExpired ? .disabled : controlState
	}
}
