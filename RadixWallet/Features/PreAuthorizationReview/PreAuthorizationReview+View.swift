import SwiftUI

extension PreAuthorizationReview.State {
	var viewState: PreAuthorizationReview.ViewState {
		.init(
			dAppMetadata: dAppMetadata,
			displayMode: displayMode,
			sliderResetDate: sliderResetDate,
			expiration: expiration,
			secondsToExpiration: secondsToExpiration,
			globalControlState: globalControlState,
			sliderControlState: sliderControlState,
			showRawTransactionButton: showRawTransactionButton
		)
	}
}

// MARK: - PreAuthorizationReview.View
extension PreAuthorizationReview {
	struct ViewState: Equatable {
		let dAppMetadata: DappMetadata.Ledger?
		let displayMode: Common.DisplayMode
		let sliderResetDate: Date
		let expiration: Expiration?
		let secondsToExpiration: Int?
		let globalControlState: ControlState
		let sliderControlState: ControlState
		let showRawTransactionButton: Bool

		var dAppName: String? {
			dAppMetadata?.name?.rawValue
		}
	}

	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview>

		@SwiftUI.State private var showNavigationTitle = false

		private let coordSpace: String = "PreAuthorizationReviewCoordSpace"
		private let navTitleID: String = "PreAuthorizationReview.title"
		private let showTitleHysteresis: CGFloat = .small3

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				content(viewStore)
					.controlState(viewStore.globalControlState)
					.background(.app.white)
					.toolbar {
						ToolbarItem(placement: .principal) {
							if showNavigationTitle {
								navigationTitle(dAppName: viewStore.dAppName)
							}
						}
					}
					.onAppear {
						store.send(.view(.appeared))
					}
			}
		}

		private func navigationTitle(dAppName: String?) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Text("Review your Pre-Authorization")
					.textStyle(.body2Header)
					.foregroundColor(.app.gray1)

				if let dAppName {
					Text("Proposed by \(dAppName)")
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
			}
		}

		private func content(_ viewStore: ViewStoreOf<PreAuthorizationReview>) -> some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: .zero) {
					header(dAppMetadata: viewStore.dAppMetadata)

					Group {
						if let rawContent = viewStore.displayMode.rawTransaction {
							rawTransaction(rawContent)
						} else {
							details(viewStore.showRawTransactionButton)
						}
					}
					.background(Common.gradientBackground)
					.clipShape(RoundedRectangle(cornerRadius: .small1))
					.padding(.horizontal, .small2)

					feesInformation(dAppName: viewStore.dAppName)
						.padding(.top, .small2)
						.padding(.horizontal, .small2)

					expiration(viewStore.expiration, secondsToExpiration: viewStore.secondsToExpiration)

					ApprovalSlider(
						title: "Slide to sign and return",
						resetDate: viewStore.sliderResetDate
					) {}
						.controlState(viewStore.sliderControlState)
						.padding(.horizontal, .medium2)
				}
				.animation(.easeInOut, value: viewStore.displayMode.rawTransaction)
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

		private func header(dAppMetadata: DappMetadata.Ledger?) -> some SwiftUI.View {
			Common.HeaderView(
				kind: .preAuthorization,
				name: dAppMetadata?.name?.rawValue,
				thumbnail: dAppMetadata?.thumbnail
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

		private func details(_ showRawTransactionButton: Bool) -> some SwiftUI.View {
			sections
				.padding(.top, .large2 + .small3)
				.padding(.horizontal, .small1)
				.padding(.bottom, .medium1)
				.overlay(alignment: .topTrailing) {
					if showRawTransactionButton {
						Button(asset: AssetResource.code) {
							store.send(.view(.toggleDisplayModeButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)
						.padding(.medium3)
					}
				}
		}

		private var sections: some SwiftUI.View {
			let childStore = store.scope(state: \.sections, action: \.child.sections)
			return Common.Sections.View(store: childStore)
		}

		private func feesInformation(dAppName: String?) -> some SwiftUI.View {
			HStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .zero) {
					Text("Pre-authorization will be returned to \(dAppName ?? "dApp") for processing.")
						.foregroundStyle(.app.gray1)

					Text("Network fees will be paid by the dApp")
						.foregroundStyle(.app.gray2)
				}
				.lineSpacing(0)
				.textStyle(.body2Regular)

				Spacer(minLength: .small2)

				InfoButton(.preauthorizations)
			}
			.padding(.vertical, .medium3)
			.padding(.horizontal, .medium2)
			.background(Color.app.gray5)
			.clipShape(RoundedRectangle(cornerRadius: .small1))
		}

		@ViewBuilder
		private func expiration(_ expiration: Expiration?, secondsToExpiration: Int?) -> some SwiftUI.View {
			Group {
				switch expiration {
				case .atTime:
					if let seconds = secondsToExpiration {
						if seconds > 0 {
							let value = formatTime(seconds: seconds)
							Text("Valid for the next **\(value)**")
						} else {
							Text("This PreAuthorization is no longer valid")
						}
					}

				case let .window(seconds):
					let value = formatTime(seconds: seconds)
					Text("Valid for **\(value) after approval**")

				case nil:
					Color.clear
				}
			}
			.textStyle(.body2Regular)
			.foregroundStyle(.app.account4pink)
			.padding(.horizontal, .medium1)
			.frame(minHeight: .huge2)
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
	var globalControlState: ControlState {
		reviewedPreAuthorization != nil ? .enabled : .loading(.global(text: "Incoming PreAuthorization"))
	}

	var sliderControlState: ControlState {
		isExpired ? .disabled : globalControlState
	}

	var showRawTransactionButton: Bool {
		globalControlState == .enabled
	}
}
