import SwiftUI

// MARK: - DAppsDirectory.View
extension DAppsDirectory {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<DAppsDirectory>
		@SwiftUI.State var selection: Int = 0

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					headerView()
					if selection == 0 {
						AllDapps.View(store: store.scope(state: \.allDapps, action: \.child.allDapps))
					} else {
						AuthorizedDappsFeature.View(store: store.scope(state: \.approvedDapps, action: \.child.approvedDapps))
					}
				}
				.background(.primaryBackground)
			}
		}

		@ViewBuilder
		func headerView() -> some SwiftUI.View {
			VStack {
				HStack {
					Spacer()
					Text(L10n.DappDirectory.title)
						.foregroundColor(Color.primaryText)
						.textStyle(.body1Header)
					Spacer()
				}
				.padding(.horizontal, .medium3)

				Picker("", selection: $selection) {
					Text(L10n.Discover.View.All.dapps)
						.tag(0)
					Text(L10n.Discover.View.Approved.dapps)
						.tag(1)
				}
				.tint(.primaryBackground)
				.pickerStyle(.segmented)
				.padding(.horizontal, .medium3)
			}
			.padding(.top, .small3)
			.padding(.bottom, .small1)
			.background(.primaryBackground)
		}
	}
}

extension DAppsDirectoryClient.DApp.Category {
	var title: String {
		switch self {
		case .defi:
			L10n.DappDirectory.CategoryDefi.title
		case .dao:
			L10n.DappDirectory.CategoryDao.title
		case .utility:
			L10n.DappDirectory.CategoryUtility.title
		case .meme:
			L10n.DappDirectory.CategoryMeme.title
		case .nft:
			L10n.DappDirectory.CategoryNFT.title
		case .other:
			L10n.DappDirectory.CategoryOther.title
		}
	}
}

extension DAppsDirectory {
	@MainActor
	@ViewBuilder
	static func loadedView(
		dAppsCategories: DAppsDirectory.DAppsCategories,
		dappsWithClaims: Set<DappDefinitionAddress> = [],
		onDAppSelected: @escaping (DApp) -> Void,
	) -> some SwiftUI.View {
		ForEach(dAppsCategories) { dAppCategory in
			Section {
				VStack(spacing: .small1) {
					ForEach(dAppCategory.dApps) { dApp in
						Card {
							onDAppSelected(dApp)
						} contents: {
							VStack(alignment: .leading, spacing: .zero) {
								PlainListRow(dApp: dApp)

								if dappsWithClaims.contains(dApp.id) {
									StatusMessageView(text: L10n.AuthorizedDapps.pendingDeposit, type: .warning, useNarrowSpacing: true)
										.padding(.horizontal, .medium1)
										.padding(.bottom, .medium3)
								}

								DAppsDirectory.dAppTags(dApp)
							}
						}
					}
				}
			} header: {
				Text(dAppCategory.category.title)
					.textStyle(.sectionHeader)
					.flushedLeft
			}
		}
	}

	@MainActor
	@ViewBuilder
	static func loadingView() -> some SwiftUI.View {
		ForEach(0 ..< 10) { _ in
			Card {
				VStack(alignment: .leading, spacing: .zero) {
					PlainListRow(
						context: .dappAndPersona,
						title: "placeholder",
						subtitle: "placeholder placeholder placeholder placeholder placeholder placeholder placeholder",
						accessory: nil,
						icon: {
							Thumbnail(.dapp, url: nil)
						}
					)
					.redacted(reason: .placeholder)
					.shimmer(active: true, config: .accountResourcesLoading)
				}
			}
		}
	}

	@MainActor
	@ViewBuilder
	static func failedView(err: Error) -> some SwiftUI.View {
		VStack(spacing: .zero) {
			Image(systemName: "arrow.clockwise")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(.small)

			Text(L10n.DappDirectory.Error.heading)
				.foregroundStyle(.primaryText)
				.textStyle(.body1Header)
				.padding(.top, .medium3)
			Text(L10n.DappDirectory.Error.message)
				.foregroundStyle(.secondaryText)
				.textStyle(.body1HighImportance)
				.padding(.top, .small3)
		}
		.padding(.top, .huge1)
		.frame(maxWidth: .infinity)
	}

	@MainActor
	@ViewBuilder
	static func dAppTags(_ dApp: DApp) -> some SwiftUI.View {
		if !dApp.tags.isEmpty {
			FlowLayout(rowsLimit: 2) {
				ForEach(dApp.tags, id: \.self) {
					OnLedgerTagView(tag: $0)
				}
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium3)
			.background(.cardBackgroundSecondary)
		}
	}
}

extension PlainListRow where Accessory == Image, Bottom == StackedHints, Icon == Thumbnail {
	init(dApp: DAppsDirectory.DApp) {
		self.init(
			context: .dappAndPersona,
			title: dApp.name,
			subtitle: dApp.description,
			icon: {
				Thumbnail(.dapp, url: dApp.thumbnail)
			}
		)
	}
}
