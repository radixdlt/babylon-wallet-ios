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
			showDepositingHeading: depositing != nil,
			showCustomizeGuaranteesButton: true
		)
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	public struct ViewState: Equatable {
		let message: String?
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
								TransactionHeading("MESSAGE") // TODO:  localize
									.padding(.bottom, .small2)
								TransactionMessageView(message: message)
									.padding(.bottom, .medium2)
							}

							ActionsView(store: store)
								.padding(.bottom, .medium1)

							Separator()
								.padding(.bottom, .medium1)

							let feeStore = store.scope(state: \.networkFee) { .child(.networkFee($0)) }
							TransactionReviewNetworkFee.View(store: feeStore)

							Button("Approve", asset: AssetResource.lock) { // TODO:  localize
								viewStore.send(.approveTapped)
							}
							.buttonStyle(.primaryRectangular)
						}
						.padding(.horizontal, .medium3)
					}
					.background(.app.gray5)
					.navigationTitle("Review transaction") // TODO:  localize
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								viewStore.send(.closeTapped)
							}
						}
						ToolbarItem(placement: .automatic) {
							Button {
								viewStore.send(.closeTapped)
							} label: {
								Image(asset: AssetResource.code)
							}
							.buttonStyle(.secondaryRectangular)
						}
					}
				}
			}
			.onAppear {
				//				decodeActions()
			}
		}
	}
}

// MARK: - TransactionReview.View.ActionsView
extension TransactionReview.View {
	// MARK: - TransactionActionsView
	struct ActionsView: View {
		let store: StoreOf<TransactionReview>

		var body: some View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				let withdrawingStore = store.scope(state: \.withdrawing) { .child(.account(id: $0, action: $1)) }
				IfLetStore(withdrawingStore) { accountsStore in
					TransactionHeading("WITHDRAWING") // TODO:  localize
					Card(insetContents: true) {
						ForEachStore(accountsStore) { accountStore in
							TransactionReviewAccount.View(store: accountStore)
						}
					}
				}
				VStack(spacing: .medium2) {
					let usedDappsStore = store.scope(state: \.usedDapps) { .child(.dapp($0)) }
					TransactionReviewDappsUsed.View(store: usedDappsStore)

					if viewStore.showDepositingHeading {
						TransactionHeading("DEPOSITING") // TODO:  localize
					}
				}
				.background(alignment: .trailing) {
					Rectangle()
						.fill(.red)
						.frame(width: 1)
						.padding(.trailing, SpeechbubbleShape.triangleInset)
				}

				let depositingStore = store.scope(state: \.depositing) { .child(.account(id: $0, action: $1)) }
				IfLetStore(depositingStore) { accountsStore in
					Card(insetContents: true) {
						ForEachStore(accountsStore) { accountStore in
							TransactionReviewAccount.View(store: accountStore)
						}

						if viewStore.showCustomizeGuaranteesButton {
							Button("Customize guarantees") { // TODO: 
								viewStore.send(.customizeGuaranteesTapped)
							}
							.textStyle(.body1Header)
							.foregroundColor(.app.blue2)
							.padding(.vertical, .small3)
						}
					}
				}
			}

			//			.overlay(alignment: .trailing) {
			//				Rectangle()
			//					.fill(.red)
			//					.frame(width: 2)
			//					.padding(.vertical, 10)
			//					.padding(.trailing, SpeechbubbleShape.triangleInset)
			//			}
			//			.border(.purple)
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
						Text(presenter.name)
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
			.padding(.bottom, .small1)
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - TransactionReview_Preview
// struct TransactionReview_Preview: PreviewProvider {
//	static var previews: some View {
//		TransactionReview.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: TransactionReview()
//			)
//		)
//	}
// }
//
// extension TransactionReview.State {
//	public static let previewValue = Self()
// }
// #endif

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
