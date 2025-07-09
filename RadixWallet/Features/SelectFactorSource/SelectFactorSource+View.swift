import SwiftUI

// MARK: - SelectFactorSource.View
extension SelectFactorSource {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<SelectFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium2)
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
				kind: .extended(linkedEntities: item.value.linkedEntities)
			)
			let mode = FactorSourceCard.Mode.selection(
				type: .radioButton,
				isSelected: item.value.selectability == .unselectable ? false : item.isSelected
			)

			FactorSourceCard(
				kind: kind,
				mode: mode,
				messages: item.value.messages
			) { _ in
				item.action()
			}
			.opacity(item.value.opacity)
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

		return sheet(store: destinationStore.scope(state: \.addSecurityFactor, action: \.addSecurityFactor)) {
			AddFactorSource.Coordinator.View(store: $0)
		}
		.sheet(store: destinationStore.scope(state: \.addNewP2PLink, action: \.addNewP2PLink)) {
			NewConnection.View(store: $0)
		}
	}
}
