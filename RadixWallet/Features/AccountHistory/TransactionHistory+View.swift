import ComposableArchitecture
import SwiftUI

// MARK: - TransactionHistory.View
extension TransactionHistory {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionHistory>

		public init(store: StoreOf<TransactionHistory>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
					let accountHeader = AccountHeaderView(account: viewStore.account)

					let selection = viewStore.binding(get: \.selectedPeriod, send: ViewAction.selectedPeriod)

					VStack(spacing: .zero) {
						HScrollBarDummy()
							.padding(.vertical, .small3)

						ScrollView {
							LazyVStack(spacing: .small1, pinnedViews: [.sectionHeaders]) {
								accountHeader
									.measurePosition(View.accountDummy, coordSpace: View.coordSpace)
									.opacity(0)

								ForEach(viewStore.sections) { section in
									SectionView(section: section)
								}
							}
						}
						.scrollIndicators(.never)
						.coordinateSpace(name: View.coordSpace)
					}
					.background(.app.gray5)
					.overlayPreferenceValue(PositionsPreferenceKey.self, alignment: .top) { positions in
						let rect = positions[View.accountDummy]
						ZStack(alignment: .top) {
							if let rect {
								accountHeader
									.offset(y: rect.minY)
							}

							let scrollBarOffset = max(rect?.maxY ?? 0, 0)
							HScrollBar(items: viewStore.periods, selection: selection)
								.padding(.vertical, .small3)
								.background(.app.white)
								.offset(y: scrollBarOffset)
						}
					}
					.clipShape(Rectangle())
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						CloseButton {
							store.send(.view(.closeTapped))
						}
					}
					ToolbarItem(placement: .topBarTrailing) {
						Button(asset: AssetResource.transactionHistoryFilterList) {}
					}
				}
				.navigationTitle("History") // FIXME: Strings
				.navigationBarTitleDisplayMode(.inline)
			}
			.onAppear {
				store.send(.view(.onAppear))
			}
		}

		private static let coordSpace = "TransactionHistory"
		private static let accountDummy = "SmallAccountCardDummy"
	}

	struct SectionView: SwiftUI.View {
		let section: TransactionHistory.State.TransactionSection

		var body: some SwiftUI.View {
			Section {
				ForEach(section.transactions, id: \.self) { transaction in
					TransactionView(transaction: transaction)
						.padding(.horizontal, .medium3)
				}
			} header: {
				SectionHeaderView(title: section.title)
			}
		}
	}

	struct AccountHeaderView: SwiftUI.View {
		let account: Profile.Network.Account

		var body: some SwiftUI.View {
			SmallAccountCard(account: account)
				.roundedCorners(radius: .small1)
				.padding(.horizontal, .medium3)
				.padding(.top, .medium3)
				.background(.app.white)
		}
	}

	struct SectionHeaderView: SwiftUI.View {
		let title: String

		var body: some SwiftUI.View {
			Text(title)
				.textStyle(.body2Header)
				.foregroundStyle(.app.gray2)
				.padding(.horizontal, .medium3)
				.padding(.top, .small1)
				.padding(.bottom, .small2)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.app.gray5)
		}
	}
}

// MARK: - TransactionHistory.TransactionView
extension TransactionHistory {
	struct TransactionView: SwiftUI.View {
		let transaction: TransactionHistoryItem

		init(transaction: TransactionHistoryItem) {
			self.transaction = transaction
		}

		var body: some SwiftUI.View {
			Card(.app.white) {
				VStack(spacing: 0) {
					if let message = transaction.message {
						MessageView(message: message)
							.padding(.bottom, -.small3)
					}

					VStack(spacing: .small1) {
						if !transaction.withdrawals.isEmpty {
							TransfersActionView(type: .withdrawal, resources: transaction.withdrawals)
								.padding(.horizontal, .medium3)
						}

						if !transaction.deposits.isEmpty {
							TransfersActionView(type: .deposit, resources: transaction.deposits)
								.padding(.horizontal, .medium3)
						}
					}
					.overlay(alignment: .topTrailing) {
						TimeStampView(manifestClass: transaction.manifestClass, time: transaction.time)
							.padding(.trailing, .medium3)
					}
					.padding(.top, .small1)
				}
				.padding(.bottom, .medium3)
			}
		}

		var time: Date {
			transaction.time
		}

		var manifestClass: GatewayAPI.ManifestClass? {
			transaction.manifestClass
		}

		struct MessageView: SwiftUI.View {
			let message: String

			var body: some SwiftUI.View {
				let inset: CGFloat = 2
				Text(message)
					.textStyle(.body2Regular)
					.foregroundColor(.app.gray1)
					.padding(.medium3)
					.frame(maxWidth: .infinity, alignment: .leading)
					.inFlatBottomSpeechbubble(inset: inset)
					.padding(.top, inset)
					.padding(.horizontal, inset)
			}
		}

		struct TimeStampView: SwiftUI.View {
			let manifestClass: GatewayAPI.ManifestClass?
			let time: Date

			var body: some SwiftUI.View {
				Text("\(manifestClassLabel) • \(timeLabel)")
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
			}

			private var manifestClassLabel: String {
				switch manifestClass {
				case .general: "General" // FIXME: Strings
				case .transfer: "Transfer"
				case .poolContribution: "Contribution"
				case .poolRedemption: "Redemption"
				case .validatorStake: "Stake"
				case .validatorUnstake: "Unstake"
				case .validatorClaim: "Claim"
				case .accountDepositSettingsUpdate: "Deposit Settings"
				case .none: "Other"
				}
			}

			private var timeLabel: String {
				time.formatted(date: .omitted, time: .shortened)
			}
		}

		struct TransfersActionView: SwiftUI.View {
			let type: TransferType
			let resources: [ResourceBalance.ViewState]

			enum TransferType {
				case withdrawal
				case deposit
			}

			var body: some SwiftUI.View {
				VStack {
					HStack(spacing: .zero) {
						Image(asset: asset)
							.padding(.trailing, .small3)

						Text(label)
							.textStyle(.body2Header)
							.foregroundColor(textColor)

						Spacer()
					}

					ResourceBalancesView(resources)
				}
			}

			private var asset: ImageAsset {
				switch type {
				case .deposit:
					AssetResource.transactionHistoryDeposit
				case .withdrawal:
					AssetResource.transactionHistoryWithdrawal
				}
			}

			private var label: String {
				switch type {
				case .deposit:
					"Deposited"
				case .withdrawal:
					"Withdrawn"
				}
			}

			private var textColor: Color {
				switch type {
				case .deposit:
					.app.green1
				case .withdrawal:
					.app.gray1
				}
			}
		}
	}
}

// MARK: - ScrollBarItem
public protocol ScrollBarItem: Identifiable {
	var caption: String { get }
}

// MARK: - DateRangeItem
public struct DateRangeItem: ScrollBarItem, Sendable, Hashable {
	public var id: Date { startDate }
	public let caption: String
	let startDate: Date
	let endDate: Date
	var range: Range<Date> { startDate ..< endDate }
}

// MARK: - HScrollBar
public struct HScrollBar<Item: ScrollBarItem>: View {
	let items: [Item]
	@Binding var selection: Item.ID

	public var body: some View {
		ScrollView(.horizontal) {
			HStack(spacing: .zero) {
				ForEach(items) { item in
					let isSelected = item.id == selection
					Button {
						selection = item.id
					} label: {
						Text(item.caption.localizedUppercase)
							.foregroundStyle(isSelected ? .app.gray1 : .app.gray2)
					}
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small2)
					.measurePosition(item.id, coordSpace: HScrollBar.coordSpace)
					.padding(.horizontal, .small3)
					.animation(.default, value: isSelected)
				}
			}
			.coordinateSpace(name: HScrollBar.coordSpace)
			.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
				if let rect = positions[selection] {
					Capsule()
						.fill(.app.gray4)
						.frame(width: rect.width, height: rect.height)
						.position(x: rect.midX, y: rect.midY)
						.animation(.default, value: rect)
				}
			}
			.padding(.vertical, .small1)
			.padding(.horizontal, .medium3)
		}
		.scrollIndicators(.never)
	}

	private static var coordSpace: String { "HScrollBar.HStack" }
}

// MARK: - HScrollBarDummy
public struct HScrollBarDummy: View {
	public var body: some View {
		Text("DUMMY")
			.foregroundStyle(.clear)
			.padding(.vertical, 2 * .small2)
			.frame(maxWidth: .infinity)
	}
}

extension View {
	public func measurePosition(_ id: AnyHashable, coordSpace: String) -> some View {
		background {
			GeometryReader { proxy in
				Color.clear
					.preference(key: PositionsPreferenceKey.self, value: [id: proxy.frame(in: .named(coordSpace))])
			}
		}
	}
}

// MARK: - PositionsPreferenceKey
private enum PositionsPreferenceKey: PreferenceKey {
	static var defaultValue: [AnyHashable: CGRect] = [:]

	static func reduce(value: inout [AnyHashable: CGRect], nextValue: () -> [AnyHashable: CGRect]) {
		value.merge(nextValue()) { $1 }
	}
}

// "ViewState"

extension TransactionHistory.State.TransactionSection {
	var title: String {
		day.formatted(date: .abbreviated, time: .omitted)
	}
}
