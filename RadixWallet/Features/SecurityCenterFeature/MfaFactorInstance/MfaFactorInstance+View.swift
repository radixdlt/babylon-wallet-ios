import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - MfaFactorInstance.View
extension MfaFactorInstance {
	struct View: SwiftUI.View {
		let store: StoreOf<MfaFactorInstance>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium3) {
						activeResourcesSection
					}
					.padding(.medium3)
				}
				.scrollBounceBehavior(.basedOnSize)
				.onFirstAppear {
					store.send(.appeared)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.FactorSources.Detail.mfaSignatureResourceTitle)
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							store.send(.continueTapped)
						} label: {
							Image(systemName: "plus")
								.frame(.smallest)
								.foregroundColor(.primaryText)
								.frame(.toolbarButtonHeight)
								.glassToolbarIconButtonSurface()
						}
						.buttonStyle(.plain)
						.contentShape(Circle())
						.accessibilityLabel("Get new instance")
					}
				}
			}
			.destinations(with: store)
		}
	}
}

private extension MfaFactorInstance.View {
	var activeResourcesSection: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text("Currently active signature resources")
				.textStyle(.body1Header)
				.foregroundStyle(.primaryText)

			switch store.activeUsages {
			case .idle, .loading:
				HStack {
					ProgressView()
					Spacer(minLength: .zero)
				}
				.padding(.medium2)
				.frame(maxWidth: .infinity, alignment: .leading)
				.addressBookEntrySurface()

			case let .success(usages):
				if usages.isEmpty {
					emptyState
				} else {
					VStack(spacing: .small2) {
						ForEach(Array(usages.enumerated()), id: \.element.signatureResource) { index, usage in
							ActiveUsageCard(
								index: index,
								usage: usage,
								onFactorSourceTap: { factorSource in
									store.send(.factorSourceTapped(factorSource))
								}
							)
						}
					}
				}

			case .failure:
				emptyState
			}
		}
	}

	var emptyState: some View {
		Text("A signature resource will appear here once it is used to securify an account.")
			.textStyle(.body1Regular)
			.foregroundStyle(.secondaryText)
			.padding(.medium2)
			.frame(maxWidth: .infinity, alignment: .leading)
			.addressBookEntrySurface()
	}
}

// MARK: - ActiveUsageCard
private struct ActiveUsageCard: View {
	let index: Int
	let usage: MfaFactorInstance.State.ActiveUsage
	let onFactorSourceTap: (FactorSource) -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: .small3) {
			SignatureResourceCard(
				index: index,
				usage: usage
			)

			if !usage.accounts.isEmpty {
				Text("Used by")
					.textStyle(.body2Regular)
					.foregroundStyle(.secondaryText)

				VStack(spacing: .small2) {
					ForEach(Array(usage.accounts.enumerated()), id: \.offset) { _, account in
						UsedByAccountCard(account: account)
					}
				}
			}

			if let factorSource = usage.factorSource {
				Text("Created with")
					.textStyle(.body2Regular)
					.foregroundStyle(.secondaryText)

				Button {
					onFactorSourceTap(factorSource)
				} label: {
					FactorSourceCard(
						kind: .instance(
							factorSource: factorSource,
							kind: .short(showDetails: false)
						),
						mode: .display,
						surface: .glass(interactive: true)
					)
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
			}
		}
		.padding(.medium2)
		.frame(maxWidth: .infinity, alignment: .leading)
		.addressBookEntrySurface()
	}
}

// MARK: - SignatureResourceCard
private struct SignatureResourceCard: View {
	let index: Int
	let usage: MfaFactorInstance.State.ActiveUsage

	var body: some View {
		HStack(spacing: .small2) {
			Thumbnail(.nft, url: nil, size: .small)

			VStack(alignment: .leading, spacing: .small3) {
				Text("Signature Resource #\(index + 1)")
					.textStyle(.body1Header)
					.foregroundColor(.primaryText)
					.lineLimit(1)

				AddressView(.address(.nonFungibleGlobalID(usage.signatureResource)))
					.textStyle(.body2Regular)
					.foregroundColor(.secondaryText)
			}

			Spacer(minLength: .zero)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.medium2)
		.addressBookEntrySurface()
	}
}

// MARK: - UsedByAccountCard
private struct UsedByAccountCard: View {
	let account: MfaFactorInstance.State.UsedByAccount

	var body: some View {
		if let profileAccount = account.profileAccount {
			AccountCard(kind: .display(addCornerRadius: false), account: profileAccount)
		} else {
			HStack(spacing: .small2) {
				Text(account.addressBookName ?? L10n.Common.account)
					.textStyle(.body1Header)
					.foregroundColor(.primaryText)
					.lineLimit(1)

				Spacer(minLength: .small2)

				AddressView(.address(.account(account.address)))
					.foregroundColor(.secondaryText)
					.lineLimit(1)
					.layoutPriority(1)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.medium2)
			.addressBookEntrySurface()
		}
	}
}

private extension StoreOf<MfaFactorInstance> {
	var destination: PresentationStoreOf<MfaFactorInstance.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<MfaFactorInstance>) -> some View {
		let destinationStore = store.destination
		return factorSourceDetail(with: destinationStore)
			.selectFactorSource(with: destinationStore)
			.addressDetails(with: destinationStore)
	}

	private func factorSourceDetail(with destinationStore: PresentationStoreOf<MfaFactorInstance.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.factorSourceDetail, action: \.factorSourceDetail)) { store in
			FactorSourceDetail.View(store: store)
		}
	}

	private func selectFactorSource(with destinationStore: PresentationStoreOf<MfaFactorInstance.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.selectFactorSource, action: \.selectFactorSource)) { store in
			SelectFactorSource.View(store: store)
				.withNavigationBar {
					destinationStore.send(.dismiss)
				}
		}
	}

	private func addressDetails(with destinationStore: PresentationStoreOf<MfaFactorInstance.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addressDetails, action: \.addressDetails)) { store in
			AddressDetails.View(store: store)
		}
	}
}
