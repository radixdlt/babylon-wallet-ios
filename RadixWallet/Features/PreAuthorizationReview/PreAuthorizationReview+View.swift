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
		let dAppMetadata: DappMetadata
		let displayMode: Common.DisplayMode
		let sliderResetDate: Date
		let expiration: Expiration
		let secondsToExpiration: Int?
		let globalControlState: ControlState
		let sliderControlState: ControlState
		let showRawManifestButton: Bool
	}

	@MainActor
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
								navigationTitle(dAppName: viewStore.dAppMetadata.name)
							}
						}
					}
					.onAppear {
						store.send(.view(.appeared))
					}
					.destinations(with: store)
			}
		}

		private func navigationTitle(dAppName: String?) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Text(L10n.PreAuthorizationReview.title)
					.textStyle(.body2Header)
					.foregroundColor(.app.gray1)

				if let dAppName {
					Text(L10n.InteractionReview.subtitle(dAppName))
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
						if let manifest = viewStore.displayMode.rawManifest {
							rawManifest(manifest)
						} else {
							details(viewStore.showRawManifestButton)
						}
					}
					.background(Common.gradientBackground)
					.clipShape(RoundedRectangle(cornerRadius: .small1))
					.padding(.horizontal, .small2)

					feesInformation(dAppName: viewStore.dAppMetadata.name)
						.padding(.top, .small2)
						.padding(.horizontal, .small2)

					expiration(viewStore.expiration, secondsToExpiration: viewStore.secondsToExpiration)

					ApprovalSlider(
						title: L10n.PreAuthorizationReview.slideToSign,
						resetDate: viewStore.sliderResetDate
					) {
						store.send(.view(.approvalSliderSlid))
					}
					.controlState(viewStore.sliderControlState)
					.padding(.horizontal, .medium2)
					.padding(.bottom, .large3)
				}
				.animation(.easeInOut, value: viewStore.displayMode.rawManifest)
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

		private func header(dAppMetadata: DappMetadata) -> some SwiftUI.View {
			Common.HeaderView(
				kind: .preAuthorization,
				name: dAppMetadata.name,
				thumbnail: dAppMetadata.thumbnail
			)
			.measurePosition(navTitleID, coordSpace: coordSpace)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium3)
		}

		private func rawManifest(_ manifest: String) -> some SwiftUI.View {
			Common.RawManifestView(manifest: manifest) {
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
		private func expiration(_ expiration: Expiration, secondsToExpiration: Int?) -> some SwiftUI.View {
			Group {
				switch expiration {
				case .atTime:
					if let seconds = secondsToExpiration {
						if seconds > 0 {
							let value = TimeFormatter.format(seconds: seconds)
							Text(markdown: L10n.PreAuthorizationReview.Expiration.atTime(value), emphasizedColor: .app.account4pink, emphasizedFont: .app.body2Link)
						} else {
							Text(L10n.PreAuthorizationReview.Expiration.expired)
						}
					}

				case let .afterDelay(value):
					let value = TimeFormatter.format(seconds: Int(value.expireAfterSeconds))
					Text(markdown: L10n.PreAuthorizationReview.Expiration.afterDelay(value), emphasizedColor: .app.account4pink, emphasizedFont: .app.body2Link)
				}
			}
			.textStyle(.body2Regular)
			.foregroundStyle(.app.account4pink)
			.padding(.horizontal, .medium1)
			.frame(minHeight: .huge2)
		}
	}
}

private extension PreAuthorizationReview.State {
	var globalControlState: ControlState {
		preview != nil ? .enabled : .loading(.global(text: L10n.PreAuthorizationReview.loading))
	}

	var sliderControlState: ControlState {
		isExpired || isApprovalInProgress ? .disabled : globalControlState
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
