import FeaturePrelude

extension TransactionReviewDappsUsed.State {
	var viewState: TransactionReviewDappsUsed.ViewState {
		let knownDapps = dApps.compactMap(\.knownDapp)
		return .init(knownDapps: knownDapps, unknownDappCount: dApps.count - knownDapps.count)
	}
}

extension TransactionReview.LedgerEntity {
	fileprivate var knownDapp: TransactionReviewDappsUsed.ViewState.KnownDapp? {
		guard let metadata else { return nil }
		return .init(id: id, thumbnail: metadata.thumbnail, name: metadata.name, description: metadata.description)
	}
}

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewDappsUsed {
	public struct ViewState: Equatable {
		let knownDapps: [KnownDapp]
		let unknownDappCount: Int

		struct KnownDapp: Identifiable, Equatable {
			let id: AccountAddress.ID
			let thumbnail: URL?
			let name: String
			let description: String?
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewDappsUsed>
		let isExpanded: Bool

		public init(store: StoreOf<TransactionReviewDappsUsed>, isExpanded: Bool) {
			self.store = store
			self.isExpanded = isExpanded
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// If this is done in the if statement the compiler faints
				let showUnknownDapps = viewStore.unknownDappCount > 0

				VStack(alignment: .trailing, spacing: .medium2) {
					Button {
						viewStore.send(.expandTapped)
					} label: {
						HeadingLabel(isExpanded: isExpanded)
					}
					.background(.app.gray5)
					.padding(.trailing, .medium3)

					if isExpanded {
						VStack(spacing: .small2) {
							ForEach(viewStore.knownDapps) { dApp in
								Button {
									viewStore.send(.dappTapped(dApp.id))
								} label: {
									DappView(type: .known(name: dApp.name, thumbnail: dApp.thumbnail, description: dApp.description))
								}
							}
							if showUnknownDapps {
								DappView(type: .unknown(count: viewStore.unknownDappCount))
							}
						}
						.transition(.opacity.combined(with: .scale(scale: 0.95)))
						.background(.app.gray5)
					}
				}
				.animation(.easeInOut, value: isExpanded)
			}
		}

		struct HeadingLabel: SwiftUI.View {
			let isExpanded: Bool

			var body: some SwiftUI.View {
				HStack(spacing: .small3) {
					Text(L10n.TransactionReview.usingDappsHeading)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray2)
					Image(asset: isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
						.renderingMode(.original)
				}
			}
		}

		struct DappView: SwiftUI.View {
			private let dAppBoxWidth: CGFloat = 190

			let type: DappType

			var body: some SwiftUI.View {
				HStack(spacing: 0) {
					switch type {
					case let .known(name, url, description):
						if let url {
							DappPlaceholder(size: .smaller)
						} else {
							DappPlaceholder(known: true, size: .smaller)
						}

						Text(name)
							.lineLimit(2)
							.padding(.leading, .small2)

					case let .unknown(count):
						DappPlaceholder(known: false, size: .smaller)
							.padding(.trailing, .small2)

						Text(L10n.TransactionReview.UsingDapps.unknownComponents(count))
							.lineLimit(2)
					}

					Spacer(minLength: 0)
				}
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.multilineTextAlignment(.leading)
				.padding(.small2)
				.frame(width: dAppBoxWidth)
				.background {
					RoundedRectangle(cornerRadius: .small2)
						.stroke(.app.gray3, style: .transactionReview)
				}
			}

			enum DappType: Equatable {
				case known(name: String, thumbnail: URL?, description: String?)
				case unknown(count: Int)
			}
		}
	}
}
