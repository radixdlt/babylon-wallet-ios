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
			showRawManifestButton: showRawManifestButton
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
		let showRawManifestButton: Bool

		var dAppName: String? {
			dAppMetadata?.name?.rawValue
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				content(viewStore)
					.controlState(viewStore.globalControlState)
					.onAppear {
						store.send(.view(.appeared))
					}
					.destinations(with: store)
			}
		}

		private func content(_ viewStore: ViewStoreOf<PreAuthorizationReview>) -> some SwiftUI.View {
			Common.VisibleHeaderView(kind: .preAuthorization, metadata: viewStore.dAppMetadata) {
				Group {
					Group {
						if let manifest = viewStore.displayMode.rawManifest {
							rawManifest(manifest)
						} else {
							details(viewStore.showRawManifestButton)
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
						title: L10n.PreAuthorizationReview.slideToSign,
						resetDate: viewStore.sliderResetDate
					) {}
						.controlState(viewStore.sliderControlState)
						.padding(.horizontal, .medium2)
				}
				.animation(.easeInOut, value: viewStore.displayMode.rawManifest)
			}
		}

		private func rawManifest(_ manifest: String) -> some SwiftUI.View {
			Common.RawManifestView(manifest: manifest) {
				store.send(.view(.copyRawManifestButtonTapped))
			} toggleAction: {
				store.send(.view(.toggleDisplayModeButtonTapped))
			}
		}

		private func details(_ showRawManifestButton: Bool) -> some SwiftUI.View {
			sections
				.padding(.top, .large2 + .small3)
				.padding(.horizontal, .small1)
				.padding(.bottom, .medium1)
				.overlay(alignment: .topTrailing) {
					if showRawManifestButton {
						Button(asset: AssetResource.code) {
							store.send(.view(.toggleDisplayModeButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)
						.padding(.medium3)
					}
				}
				.frame(minHeight: .standardButtonHeight + 2 * .medium3, alignment: .top)
		}

		private var sections: some SwiftUI.View {
			let childStore = store.scope(state: \.sections, action: \.child.sections)
			return Common.Sections.View(store: childStore)
		}

		private func feesInformation(dAppName: String?) -> some SwiftUI.View {
			HStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .zero) {
					Text(L10n.PreAuthorizationReview.Fees.title(dAppName ?? "dApp"))
						.foregroundStyle(.app.gray1)

					Text(L10n.PreAuthorizationReview.Fees.subtitle)
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
							Text(markdown: L10n.PreAuthorizationReview.Expiration.atTime(value), emphasizedColor: .app.account4pink, emphasizedFont: .app.body2Link)
						} else {
							Text(L10n.PreAuthorizationReview.Expiration.expired)
						}
					}

				case let .afterDelay(value):
					let value = formatTime(seconds: Int(value.expireAfterSeconds))
					Text(markdown: L10n.PreAuthorizationReview.Expiration.afterDelay(value), emphasizedColor: .app.account4pink, emphasizedFont: .app.body2Link)

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
		typealias S = L10n.PreAuthorizationReview.TimeFormat
		let minutes = seconds / 60
		let hours = minutes / 60
		let days = hours / 24
		if days > 0 {
			return days == 1 ? S.day : S.days(days)
		} else if hours > 0 {
			let remainingMinutes = minutes % 60
			let formatted = String(format: "%d:%02d", hours, remainingMinutes)
			return hours == 1 ? S.hour(formatted) : S.hours(formatted)
		} else if minutes > 0 {
			let remainingSeconds = seconds % 60
			let formatted = String(format: "%d:%02d", minutes, remainingSeconds)
			return minutes == 1 ? S.minute(formatted) : S.minutes(formatted)
		} else {
			return seconds == 1 ? S.second : S.seconds(seconds)
		}
	}
}

private extension PreAuthorizationReview.State {
	var globalControlState: ControlState {
		preview != nil ? .enabled : .loading(.global(text: L10n.PreAuthorizationReview.loading))
	}

	var sliderControlState: ControlState {
		isExpired ? .disabled : globalControlState
	}

	var showRawManifestButton: Bool {
		globalControlState == .enabled
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PreAuthorizationReview>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)
		return rawManifestAlert(with: destinationStore)
	}

	private func rawManifestAlert(with destinationStore: PresentationStoreOf<PreAuthorizationReview.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.rawManifestAlert, action: \.rawManifestAlert))
	}
}
