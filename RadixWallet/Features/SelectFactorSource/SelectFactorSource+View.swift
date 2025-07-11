import SwiftUI

// MARK: - SelectFactorSource.View
extension SelectFactorSource {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<SelectFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollViewReader { scroll in
					WithPerceptionTracking {
						ScrollView {
							coreView
								.padding(.horizontal, .medium3)
								.padding(.bottom, .medium2)
						}
						.onReceive(store.selectedFactorSourceId.publisher) { id in
							scroll.scrollTo(id, anchor: .center)
						}
					}
				}
				.destinations(store: store)
				.footer {
					WithControlRequirements(
						store.selectedFactorSource,
						forAction: { store.send(.view(.continueButtonTapped($0))) }
					) { action in
						Button(L10n.Common.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.onFirstAppear {
					store.send(.view(.appeared))
				}
				.background(.secondaryBackground)
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .small1) {
				topView

				Selection(
					$store.selectedFactorSource.sending(\.view.rowTapped),
					from: store.rows
				) { item in
					VStack {
						sectionHeader(item)
						card(item)
							.tag(item.value.id)
					}
				}

				Button("Add a new Security Factor") {
					store.send(.view(.addSecurityFactorTapped))
				}
				.buttonStyle(.secondaryRectangular())
				.padding(.top, .medium3)
			}
		}

		@ViewBuilder
		private func sectionHeader(_ item: SelectionItem<FactorSourcesList.Row>) -> some SwiftUI.View {
			let kind = item.value.integrity.factorSource.kind
			let isFirstOfKind = store.rows.first(where: { $0.integrity.factorSource.kind == kind }) == item.value
			if isFirstOfKind {
				VStack(alignment: .leading, spacing: .zero) {
					Text(kind.title)
						.textStyle(.body1HighImportance)
					Text(kind.details)
						.textStyle(.body1Regular)
				}
				.foregroundStyle(.secondaryText)
				.padding(.top, .medium3)
				.flushedLeft
			}
		}

		@ViewBuilder
		private func card(_ item: SelectionItem<FactorSourcesList.Row>) -> some SwiftUI.View {
			let kind = FactorSourceCard.Kind.instance(
				factorSource: item.value.integrity.factorSource,
				kind: .withEntities(linkedEntities: item.value.linkedEntities)
			)
			let mode = FactorSourceCard.Mode.selection(
				type: .radioButton,
				selectionEnabled: item.value.selectability == .selectable,
				isSelected: item.value.selectability == .unselectable ? false : item.isSelected
			)

			FactorSourceCard(
				kind: kind,
				mode: mode,
				messages: item.value.messages
			) { action in
				switch action {
				case .messageTapped:
					store.send(.view(.messageTapped(item.value)))
				case .removeTapped:
					break
				}
			}
			.onTapGesture(perform: item.action)
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .small3) {
				Text("Select Security Factor")
					.textStyle(.sheetTitle)

				Text(markdown: "Choose the security factor you will use to create the new Account.", emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
					.textStyle(.body1Regular)
					.lineSpacing(.zero)
			}
			.foregroundStyle(.primaryText)
			.multilineTextAlignment(.center)
		}
	}
}

private extension View {
	func destinations(store: StoreOf<SelectFactorSource>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)

		return addFactorSource(with: destinationStore)
			.addP2PLink(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.enterMnemonic(with: destinationStore)
	}

	private func addFactorSource(with destinationStore: PresentationStoreOf<SelectFactorSource.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addSecurityFactor, action: \.addSecurityFactor)) {
			AddFactorSource.Coordinator.View(store: $0)
		}
	}

	private func addP2PLink(with destinationStore: PresentationStoreOf<SelectFactorSource.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewP2PLink, action: \.addNewP2PLink)) {
			NewConnection.View(store: $0)
		}
	}

	private func displayMnemonic(with destinationStore: PresentationStoreOf<SelectFactorSource.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.displayMnemonic, action: \.displayMnemonic)) {
			DisplayMnemonic.View(store: $0)
		}
	}

	private func enterMnemonic(with destinationStore: PresentationStoreOf<SelectFactorSource.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.enterMnemonic, action: \.enterMnemonic)) {
			ImportMnemonicForFactorSource.View(store: $0)
				.radixToolbar(
					title: "Enter Seed Phrase"
				)
		}
	}
}
