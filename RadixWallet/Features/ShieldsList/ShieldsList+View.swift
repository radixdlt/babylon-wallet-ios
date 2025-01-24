extension ShieldsList.State {
	var main: ShieldForDisplay? {
		shields.first(where: \.isMain)
	}

	var others: [ShieldForDisplay] {
		let main = main
		return shields
			.filter { $0 != main }
	}
}

// MARK: - ShieldsList.View
extension ShieldsList {
	struct View: SwiftUI.View {
		let store: StoreOf<ShieldsList>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
						.padding(.vertical, .large2)
				}
				.radixToolbar(title: "Security Shields")
				.task {
					store.send(.view(.task))
				}
				.destinations(with: store)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				// TODO:
				if let main = store.main {
					section(text: "Default Shield", rows: [main], showChangeMain: !store.others.isEmpty)

					if !store.others.isEmpty {
						section(text: "Others", rows: store.others)
							.padding(.top, .medium3)
					}
				} else {
					section(text: nil, rows: store.others)
				}

				Button("Create New Security Shield") {
					store.send(.view(.createShieldButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)
				.padding(.vertical, .medium2)

				InfoButton(.securityshields, label: L10n.InfoLink.Title.securityshields)
			}
			.frame(maxWidth: .infinity)
		}

		private func header(_ text: String) -> some SwiftUI.View {
			Text(text)
				.textStyle(.secondaryHeader)
				.foregroundStyle(.app.gray2)
				.flushedLeft
		}

		private func section(text: String?, rows: [ShieldForDisplay], showChangeMain: Bool = false) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				if let text {
					HStack(spacing: .zero) {
						header(text)
						Spacer()
						if showChangeMain {
							Button(L10n.FactorSources.List.change) {
								store.send(.view(.changeMainButtonTapped))
							}
							.buttonStyle(.primaryText())
						}
					}
				}

				VStack(spacing: .medium3) {
					ForEachStatic(rows) { row in
						shieldCard(row)
					}
				}
			}
		}

		private func shieldCard(_ shield: ShieldForDisplay) -> some SwiftUI.View {
			HStack(spacing: .zero) {
				Image(.shieldStatusNotApplied)
					.padding(.vertical, .small2)

				VStack(alignment: .leading, spacing: .small2) {
					Text(shield.name.rawValue)
						.textStyle(.body1Header)
						.foregroundStyle(.app.gray1)

					VStack(alignment: .leading, spacing: .zero) {
						Text("Assigned to:")
							.textStyle(.body2HighImportance)

						Text("None")
							.textStyle(.body2Regular)
					}
					.foregroundStyle(.app.gray2)

					StatusMessageView(
						text: "Action required",
						type: .warning,
						useNarrowSpacing: true,
						useSmallerFontSize: true
					)
				}

				Spacer()
			}
			.centered
			.padding(.medium2)
			.background(.app.white)
			.roundedCorners(radius: .small1)
			.cardShadow
		}
	}
}

private extension StoreOf<ShieldsList> {
	var destination: PresentationStoreOf<ShieldsList.Destination> {
		func scopeState(state: State) -> PresentationState<ShieldsList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ShieldsList>) -> some View {
		let destinationStore = store.destination
		return securityShieldsSetup(with: destinationStore)
	}

	private func securityShieldsSetup(with destinationStore: PresentationStoreOf<ShieldsList.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.securityShieldsSetup, action: \.securityShieldsSetup)) {
			ShieldSetupCoordinator.View(store: $0)
		}
	}
}
