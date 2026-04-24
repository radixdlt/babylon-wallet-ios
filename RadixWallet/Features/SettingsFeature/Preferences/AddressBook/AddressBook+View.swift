import ComposableArchitecture
import SwiftUI

// MARK: - AddressBook.View
extension AddressBook {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<AddressBook>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					LazyVStack(alignment: .leading, spacing: .medium3) {
						Text(L10n.AddressBook.subtitle)
							.textStyle(.body1HighImportance)
							.foregroundColor(.secondaryText)

						if store.entries.isEmpty {
							emptyState
						} else {
							ForEachStatic(store.entries) { entry in
								entryRow(entry)
							}
						}
					}
					.padding(.medium3)
				}
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.AddressBook.title)
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							store.send(.view(.addButtonTapped))
						} label: {
							Image(systemName: "plus")
						}
					}
				}
				.task {
					store.send(.view(.task))
				}
				.destinations(with: store)
			}
		}

		private var emptyState: some SwiftUI.View {
			Text(L10n.AddressBook.emptyState)
				.textStyle(.secondaryHeader)
				.foregroundColor(.secondaryText)
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.padding(.medium3)
				.addressBookEntrySurface()
		}

		private func entryRow(_ entry: AddressBookEntry) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small3) {
				Text(entry.name.value)
					.textStyle(.body1Header)
					.foregroundColor(.primaryText)

				HStack(spacing: .small2) {
					addressView(entry.address)

					HStack(spacing: .small1) {
						actionButton(asset: AssetResource.create, accessibilityLabel: L10n.AddressBook.edit) {
							store.send(.view(.editTapped(entry)))
						}

						actionButton(asset: AssetResource.trash, accessibilityLabel: L10n.AddressBook.delete) {
							store.send(.view(.deleteTapped(entry)))
						}
					}
					.fixedSize()
				}

				if let note = entry.note, !note.isEmpty {
					Text(note)
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)
						.multilineTextAlignment(.leading)
						.lineLimit(2)
				}
			}
			.padding(.medium3)
			.addressBookEntrySurface()
		}

		@ViewBuilder
		private func addressView(_ address: Address) -> some SwiftUI.View {
			if let identifiableAddress = LedgerIdentifiable.Address(address: address) {
				AddressView(.address(identifiableAddress))
					.foregroundColor(.secondaryText)
					.frame(maxWidth: .infinity, alignment: .leading)
					.layoutPriority(1)
			} else {
				Text(address.formatted(.default))
					.textStyle(.body1Regular)
					.foregroundColor(.secondaryText)
					.lineLimit(1)
					.frame(maxWidth: .infinity, alignment: .leading)
					.layoutPriority(1)
			}
		}

		@ViewBuilder
		private func actionButton(
			asset: ImageAsset,
			accessibilityLabel: String,
			action: @escaping () -> Void
		) -> some SwiftUI.View {
			if #available(iOS 26, *) {
				Button(action: action) {
					Image(asset: asset)
						.frame(.smallest)
						.foregroundColor(.primaryText)
						.frame(.small)
						.glassEffect(.clear.interactive(), in: .circle)
				}
				.buttonStyle(.plain)
				.contentShape(Circle())
				.accessibilityLabel(accessibilityLabel)
			} else {
				Button(action: action) {
					Image(asset: asset)
						.frame(.smallest)
						.foregroundColor(.primaryText)
						.padding(.small3)
						.modifier(AddressBookIconButtonSurface())
				}
				.buttonStyle(.plain)
				.contentShape(RoundedRectangle(cornerRadius: .large2))
				.accessibilityLabel(accessibilityLabel)
			}
		}
	}
}

// MARK: - AddressBookIconButtonSurface
private struct AddressBookIconButtonSurface: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 26, *) {
			content
				.background(.clear, in: RoundedRectangle(cornerRadius: .large2))
				.glassEffect(.clear.interactive(), in: .rect(cornerRadius: .large2))
		} else {
			content
				.background(.tertiaryBackground.opacity(0.7), in: RoundedRectangle(cornerRadius: .large2))
				.overlay(
					RoundedRectangle(cornerRadius: .large2)
						.stroke(.border.opacity(0.7), lineWidth: 1)
				)
		}
	}
}

private extension StoreOf<AddressBook> {
	var destination: PresentationStoreOf<AddressBook.Destination> {
		func scopeState(state: State) -> PresentationState<AddressBook.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AddressBook>) -> some View {
		let destinationStore = store.destination
		return addEntry(with: destinationStore)
			.editEntry(with: destinationStore)
			.deleteAlert(with: destinationStore)
	}

	private func addEntry(with destinationStore: PresentationStoreOf<AddressBook.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addEntry, action: \.addEntry)) {
			AddressBookEntryForm.View(store: $0)
		}
	}

	private func editEntry(with destinationStore: PresentationStoreOf<AddressBook.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.editEntry, action: \.editEntry)) {
			AddressBookEntryForm.View(store: $0)
		}
	}

	private func deleteAlert(with destinationStore: PresentationStoreOf<AddressBook.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.deleteAlert, action: \.deleteAlert))
	}
}
