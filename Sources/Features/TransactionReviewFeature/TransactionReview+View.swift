import ComposableArchitecture
import FeaturePrelude
import Profile

extension View {
	var sectionHeading: some View {
		textStyle(.body1Header)
			.foregroundColor(.app.gray2)
	}

	var message: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
	}
}

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init(
			message: message,
			isExpandedDappUsed: dAppsUsed?.isExpanded == true,
			showDepositingHeading: depositing != nil,
			showCustomizeGuaranteesButton: true
		)
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	public struct ViewState: Equatable {
		let message: String?
		let isExpandedDappUsed: Bool
		let showDepositingHeading: Bool
		let showCustomizeGuaranteesButton: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReview>

		public init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView(showsIndicators: false) {
						VStack(spacing: 0) {
							FixedSpacer(height: .medium2)

							if let message = viewStore.message {
								TransactionHeading(L10n.TransactionReview.messageHeading)
									.padding(.bottom, .small2)
								TransactionMessageView(message: message)
							}

							let withdrawingStore = store.scope(state: \.withdrawing) { .child(.withdrawing($0)) }
							IfLetStore(withdrawingStore) { withdrawingStore in
								TransactionHeading(L10n.TransactionReview.withdrawingHeading)
									.padding(.top, .medium2)
									.padding(.bottom, .small2)
								TransactionReviewAccounts.View(store: withdrawingStore)
							}

							usingDappsSection(expanded: viewStore.isExpandedDappUsed, showDepositingHeading: viewStore.showDepositingHeading)

							let depositingStore = store.scope(state: \.depositing) { .child(.depositing($0)) }
							IfLetStore(depositingStore) { childStore in
								TransactionReviewAccounts.View(store: childStore)
							}
							.padding(.bottom, .medium1)

							Separator()
								.padding(.bottom, .medium1)

							let feeStore = store.scope(state: \.networkFee) { .child(.networkFee($0)) }
							TransactionReviewNetworkFee.View(store: feeStore)

							Button(L10n.TransactionReview.approveButtonTitle, asset: AssetResource.lock) {
								viewStore.send(.approveTapped)
							}
							.buttonStyle(.primaryRectangular)
						}
						.padding(.horizontal, .medium3)
					}
					.background(.app.gray5)
					.animation(.easeInOut, value: viewStore.isExpandedDappUsed)
					.navigationTitle(L10n.TransactionReview.title)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								viewStore.send(.closeTapped)
							}
						}
						ToolbarItem(placement: .automatic) {
							Button(asset: AssetResource.code) {
								viewStore.send(.closeTapped)
							}
							.buttonStyle(.secondaryRectangular(isInToolbar: true))
						}
					}
				}
			}
			.onAppear {
				// decodeActions()
			}
		}

		private func usingDappsSection(expanded: Bool, showDepositingHeading: Bool) -> some SwiftUI.View {
			VStack(alignment: .trailing, spacing: .medium2) {
				let usedDappsStore = store.scope(state: \.dAppsUsed) { .child(.dAppsUsed($0)) }
				IfLetStore(usedDappsStore) { childStore in
					TransactionReviewDappsUsed.View(store: childStore, isExpanded: expanded)
						.padding(.top, .medium2)
				}

				if showDepositingHeading {
					TransactionHeading(L10n.TransactionReview.depositingHeading)
						.padding(.bottom, .small2)
				}
			}
			.background(alignment: .trailing) {
				VLine()
					.stroke(.app.gray3, style: .transactionReview)
					.frame(width: 1)
					.padding(.trailing, SpeechbubbleShape.triangleInset)
			}
		}
	}
}

// MARK: - VLine
struct VLine: Shape {
	func path(in rect: CGRect) -> SwiftUI.Path {
		SwiftUI.Path { path in
			path.move(to: .init(x: rect.midX, y: rect.minY))
			path.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
	}
}

// MARK: - TransactionPresentingView
struct TransactionPresentingView: View {
	let presenters: IdentifiedArrayOf<TransactionReview.State.Dapp>
	let tapPresenterAction: (TransactionReview.State.Dapp.ID) -> Void

	var body: some View {
		Card {
			List(presenters) { presenter in
				Button {
					tapPresenterAction(presenter.id)
				} label: {
					HStack(spacing: .small1) {
						DappPlaceholder(size: .smallest)
//						Text(presenter.name)
						Spacer(minLength: 0)
					}
				}
				.padding(.horizontal, .large2)
			}
		}
	}
}

// MARK: - TransactionHeading
struct TransactionHeading: View {
	let heading: String

	init(_ heading: String) {
		self.heading = heading
	}

	var body: some View {
		Text(heading)
			.sectionHeading
			.flushedLeft(padding: .medium3)
	}
}

// MARK: - TransactionMessageView
struct TransactionMessageView: View {
	let message: String

	var body: some View {
		Speechbubble {
			Text(message)
				.message
				.flushedLeft
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
		}
	}
}

// MARK: - FixedSpacer
public struct FixedSpacer: View {
	let width: CGFloat
	let height: CGFloat

	public init(width: CGFloat = 1, height: CGFloat = 1) {
		self.width = width
		self.height = height
	}

	public var body: some View {
		Rectangle()
			.fill(.clear)
			.frame(width: width, height: height)
	}
}

extension StrokeStyle {
	static let transactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
}

extension Label where Title == Text, Icon == Image {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset) {
		self.init {
			Text(titleKey)
		} icon: {
			Image(asset: asset)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset) where S: StringProtocol {
		self.init {
			Text(title)
		} icon: {
			Image(asset: asset)
		}
	}
}

extension Button where Label == SwiftUI.Label<Text, Image> {
	public init(_ titleKey: LocalizedStringKey, asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			SwiftUI.Label(titleKey, asset: asset)
		}
	}

	public init<S>(_ title: S, asset: ImageAsset, action: @escaping () -> Void) where S: StringProtocol {
		self.init(action: action) {
			SwiftUI.Label(title, asset: asset)
		}
	}
}

extension Button where Label == Image {
	public init(asset: ImageAsset, action: @escaping () -> Void) {
		self.init(action: action) {
			Image(asset: asset)
		}
	}
}
