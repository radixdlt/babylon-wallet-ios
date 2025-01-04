// MARK: - FactorSourcesList.View
extension FactorSourcesList {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourcesList>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(spacing: .large3) {
						header(viewStore.kind.details)

						if let main = viewStore.main {
							section(text: L10n.FactorSources.List.default, rows: [main])
								.padding(.top, .medium3)

							if !viewStore.others.isEmpty {
								section(text: L10n.FactorSources.List.others, rows: viewStore.others)
							}
						} else {
							section(text: nil, rows: viewStore.others)
						}

						Button(viewStore.addTitle) {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.secondaryRectangular)

						let infoContent = viewStore.kind.infoLinkContent
						InfoButton(infoContent.item, label: infoContent.title)
					}
					.padding(.medium3)
					.padding(.bottom, .medium2)
				}
				.background(.app.gray5)
				.radixToolbar(title: viewStore.kind.title)
				.task {
					store.send(.view(.task))
				}
			}
			.destinations(with: store)
		}

		private func header(_ text: String?) -> some SwiftUI.View {
			Text(text)
				.textStyle(.body1Header)
				.foregroundStyle(.app.gray2)
				.flushedLeft
		}

		private func section(text: String?, rows: [State.Row]) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				header(text)

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
				mode: .display,
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
			L10n.FactorSources.List.passphraseAdd
		case .arculusCard:
			L10n.FactorSources.List.arculusCardAdd
		case .password:
			L10n.FactorSources.List.passwordAdd
		case .trustedContact, .securityQuestions:
			fatalError("Not implemented")
		}
	}

	var main: Row? {
		rows.first(where: \.integrity.isExplicitMain)
	}

	var others: [Row] {
		rows
			.filter { !$0.integrity.isExplicitMain }
			.sorted(by: { left, right in
				let lhs = left.integrity
				let rhs = right.integrity
				switch (lhs, rhs) {
				case let (.device(lDevice), .device(rDevice)):
					if lDevice.factorSource.isBDFS, rDevice.factorSource.isBDFS {
						return sort(lhs, rhs)
					} else {
						return lDevice.factorSource.isBDFS
					}
				default:
					return sort(lhs, rhs)
				}

			})
	}

	private func sort(_ lhs: FactorSourceIntegrity, _ rhs: FactorSourceIntegrity) -> Bool {
		lhs.factorSource.common.addedOn < rhs.factorSource.common.addedOn
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
}

private extension StoreOf<FactorSourcesList> {
	var destination: PresentationStoreOf<FactorSourcesList.Destination> {
		func scopeState(state: State) -> PresentationState<FactorSourcesList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FactorSourcesList>) -> some View {
		let destinationStore = store.destination
		return detail(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.enterMnemonic(with: destinationStore)
			.addMnemonic(with: destinationStore)
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

	private func addMnemonic(with destinationStore: PresentationStoreOf<FactorSourcesList.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.addMnemonic, action: \.addMnemonic)) {
			ImportMnemonic.View(store: $0)
		}
	}
}

