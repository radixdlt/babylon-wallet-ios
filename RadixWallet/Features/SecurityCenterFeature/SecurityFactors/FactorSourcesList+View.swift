// MARK: - FactorSourcesList.View
extension FactorSourcesList {
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourcesList>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large3) {
						header(store.kind.details)

						if let main = store.main {
							section(text: L10n.FactorSources.List.default, rows: [main], showChangeMain: !store.others.isEmpty)
								.padding(.top, .medium3)

							if !store.others.isEmpty {
								section(text: L10n.FactorSources.List.others, rows: store.others)
							}
						} else {
							section(text: nil, rows: store.others)
						}

						Button(store.addTitle) {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)

//						let infoContent = store.kind.infoLinkContent
//						InfoButton(infoContent.item, label: infoContent.title)
					}
					.padding(.medium3)
					.padding(.bottom, .medium2)
				}
				.background(Color.secondaryBackground)
				.radixToolbar(title: store.kind.title)
				.footer(visible: store.showFooter) {
					WithControlRequirements(
						store.selected,
						forAction: { store.send(.view(.continueButtonTapped($0.integrity.factorSource))) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.task {
					store.send(.view(.task))
				}
			}
			.destinations(with: store)
		}

		private func header(_ text: String) -> some SwiftUI.View {
			Text(text)
				.textStyle(.body1Header)
				.foregroundStyle(Color.secondaryText)
				.flushedLeft
		}

		private func section(text: String?, rows: [State.Row], showChangeMain: Bool = false) -> some SwiftUI.View {
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

				ForEachStatic(rows) { row in
					card(row)
				}
			}
		}

		private func card(_ row: State.Row) -> some SwiftUI.View {
			FactorSourceCard(
				kind: .instance(
					factorSource: row.integrity.factorSource,
					kind: .extended(linkedEntities: row.linkedEntities)
				),
				mode: mode(row),
				messages: row.messages
			) { action in
				switch action {
				case .removeTapped:
					break
				case .messageTapped:
					store.send(.view(.rowMessageTapped(row)))
				}
			}
			.onTapGesture {
				store.send(.view(.rowTapped(row)))
			}
			.opacity(row.opacity)
		}

		func mode(_ row: State.Row) -> FactorSourceCard.Mode {
			switch store.context {
			case .display:
				.display
			case .selection:
				.selection(type: .radioButton, isSelected: store.selected == row || row.selectability == .alreadySelected)
			}
		}
	}
}

private extension FactorSourcesList.State {
	var addTitle: String {
		switch kind {
		case .device:
			L10n.FactorSources.List.deviceAdd
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.List.ledgerAdd
		case .offDeviceMnemonic:
			L10n.FactorSources.List.offDeviceMnemonicAdd
		case .arculusCard:
			L10n.FactorSources.List.arculusCardAdd
		case .password:
			L10n.FactorSources.List.passwordAdd
		}
	}

	var showFooter: Bool {
		switch context {
		case .display: false
		case .selection: true
		}
	}
}

private extension FactorSourcesList.State.Row {
	var messages: [FactorSourceCardDataSource.Message] {
		switch status {
		case .lostFactorSource:
			[.init(text: L10n.FactorSources.List.lostFactorSource, type: .error)]
		case .seedPhraseNotRecoverable:
			[.init(text: L10n.FactorSources.List.seedPhraseNotRecoverable, type: .warning)]
		case .seedPhraseWrittenDown:
			[.init(text: L10n.FactorSources.List.seedPhraseWrittenDown, type: .success)]
		case .notBackedUp:
			[]
		}
	}

	var opacity: CGFloat {
		switch selectability {
		case .selectable: 1.0
		case .alreadySelected, .unselectable: 0.5
		}
	}
}

private extension StoreOf<FactorSourcesList> {
	var destination: PresentationStoreOf<FactorSourcesList.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FactorSourcesList>) -> some View {
		let destinationStore = store.destination
		return detail(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.enterMnemonic(with: destinationStore)
			.changeMain(with: destinationStore)
			.addNewP2PLinkSheet(with: destinationStore)
			.noP2PLinkAlert(with: destinationStore)
			.addNewLedgerSheet(with: destinationStore)
			.addFactorSource(with: destinationStore)
	}

	private func detail(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.detail, action: \.detail)) {
			FactorSourceDetail.View(store: $0)
		}
	}

	private func displayMnemonic(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.displayMnemonic, action: \.displayMnemonic)) {
			DisplayMnemonic.View(store: $0)
		}
	}

	private func enterMnemonic(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.enterMnemonic, action: \.enterMnemonic)) {
			ImportMnemonicsFlowCoordinator.View(store: $0)
		}
	}

	private func changeMain(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.changeMain, action: \.changeMain)) {
			ChangeMainFactorSource.View(store: $0)
		}
	}

	private func addNewLedgerSheet(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewLedger, action: \.addNewLedger)) {
			AddLedgerFactorSource.View(store: $0)
		}
	}

	private func addNewP2PLinkSheet(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewP2PLink, action: \.addNewP2PLink)) {
			NewConnection.View(store: $0)
		}
	}

	private func noP2PLinkAlert(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.noP2PLink, action: \.noP2PLink))
	}

	private func addFactorSource(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addFactorSource, action: \.addFactorSource)) {
			AddFactorSource.Coordinator.View(store: $0)
		}
	}
}
