// MARK: - AddressDetails.View
public extension AddressDetails {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddressDetails>
		@Environment(\.dismiss) var dismiss

		public init(store: StoreOf<AddressDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				content
					.withNavigationBar {
						dismiss()
					}
					.presentationDetents([.large])
					.presentationDragIndicator(.visible)
					.task {
						await store.send(.view(.task)).finish()
					}
					.sheet(isPresented: $store.showShare.sending(\.view.showShareChanged)) {
						ShareView(items: [store.address.address])
					}
			}
		}

		private var content: some SwiftUI.View {
			VStack(spacing: .zero) {
				top

				fullAddress
					.padding(.vertical, .medium3)

				bottom

				Spacer()
			}
			.multilineTextAlignment(.center)
			.padding([.horizontal, .bottom], .medium3)
			.overlay(alignment: .top) {
				Group {
					if store.showEnlarged {
						enlargedView
					}
				}
				.animation(.easeInOut, value: store.showEnlarged)
			}
		}

		private var top: some SwiftUI.View {
			VStack(spacing: .small2) {
				loadable(store.title) {
					ProgressView()
				} successContent: { title in
					Text(title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
				}

				if store.showQrCode {
					Text(L10n.AddressDetails.qrCode)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)

					qrCode
				}
			}
		}

		private var qrCode: some SwiftUI.View {
			Group {
				switch store.qrImage {
				case let .success(value):
					GeometryReader { proxy in
						let size = min(proxy.size.height, proxy.size.width, 275)
						Image(decorative: value, scale: 1)
							.resizable()
							.frame(width: size, height: size)
							.position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
					}
					.transition(.scale(scale: 0.95).combined(with: .opacity))
				case .failure:
					Text(L10n.AddressDetails.qrCodeFailure)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.alert)
				case .loading:
					ProgressView()
				case .idle:
					EmptyView()
				}
			}
			.animation(.easeInOut, value: store.qrImage.isSuccess)
		}

		@ViewBuilder
		private var actions: some SwiftUI.View {
			FlowLayout(multilineAlignment: .center, spacing: .large3) {
				actionButton(L10n.AddressDetails.copy, image: .copyBig) {
					store.send(.view(.copyButtonTapped))
				}
				actionButton(L10n.AddressDetails.enlarge, image: .fullScreen) {
					store.send(.view(.enlargeButtonTapped))
				}
				actionButton(L10n.AddressDetails.share, image: .share) {
					store.send(.view(.shareButtonTapped))
				}
			}
		}

		private func actionButton(_ title: String, image: ImageResource, action: @escaping () -> Void) -> some SwiftUI.View {
			Button(action: action) {
				HStack(spacing: .small3) {
					Image(image)
						.renderingMode(.template)
						.resizable()
						.frame(.icon)
						.foregroundColor(.app.gray2)
					Text(title)
						.foregroundColor(.app.gray1)
				}
			}
		}

		private var bottom: some SwiftUI.View {
			VStack(spacing: .medium3) {
				Button(L10n.AddressDetails.viewOnDashboard) {
					store.send(.view(.viewOnDashboardButtonTapped))
				}
				.buttonStyle(
					.secondaryRectangular(
						shouldExpand: true,
						trailingImage: .init(.iconLinkOut)
					)
				)
				if store.showVerifyOnLedger {
					Button(L10n.AddressDetails.verifyOnLedger) {
						store.send(.view(.verifyOnLedgerButtonTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
			}
		}
	}
}

private extension AddressDetails.View {
	var fullAddress: some SwiftUI.View {
		VStack(spacing: .medium2) {
			VStack(spacing: .small2) {
				Text(L10n.AddressDetails.fullAddress)
					.foregroundColor(.app.gray1)
				Text(colorisedText)
					.fixedSize(horizontal: false, vertical: true)
			}
			actions
		}
		.textStyle(.body1Header)
		.padding(.vertical, .medium1)
		.padding(.horizontal, .medium3)
		.background(Color.app.gray5)
		.cornerRadius(.small1)
	}

	private var colorisedText: AttributedString {
		let address = store.address
		let parts: [(raw: String, trimmed: String)] =
			switch address {
			case let .nonFungibleGlobalID(globalId):
				[
					(globalId.resourceAddress.formatted(.raw), globalId.resourceAddress.formatted(.default)),
					(globalId.localID.formatted(.raw), globalId.localID.formatted(.default)),
				]
			default:
				[(address.formatted(.raw), address.formatted(.default))]
			}

		let result = NSMutableAttributedString()
		for (index, part) in parts.enumerated() {
			var attributed = AttributedString(part.raw, foregroundColor: .app.gray2)
			let boldChars = part.trimmed.split(separator: "...")
			if let range = attributed.range(of: boldChars[0]) {
				attributed[range].foregroundColor = .app.gray1
			}
			if boldChars.count == 2, let range = attributed.range(of: boldChars[1], options: .backwards) {
				attributed[range].foregroundColor = .app.gray1
			}
			result.append(.init(attributed))
			if (index + 1) != parts.count {
				result.append(.init(AttributedString(":", foregroundColor: .app.gray2)))
			}
		}

		return .init(result)
	}
}

// MARK: - Enlarged view
private extension AddressDetails.View {
	var enlargedView: some SwiftUI.View {
		Text(enlargedText)
			.textStyle(.enlarged)
			.foregroundColor(.app.white)
			.multilineTextAlignment(.center)
			.padding(.small1)
			.background(.app.gray1.opacity(0.8))
			.cornerRadius(.small1)
			.padding(.horizontal, .large2)
			.onTapGesture {
				store.send(.view(.hideEnlargedView))
			}
			.background(enlargedViewBackrgound)
	}

	private var enlargedViewBackrgound: some View {
		Color.black.opacity(0.2)
			.frame(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
			.onTapGesture {
				store.send(.view(.hideEnlargedView))
			}
	}

	private var enlargedText: AttributedString {
		let attributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.app.green3)]
		let result = NSMutableAttributedString()
		for letter in store.address.address.unicodeScalars {
			let isDigit = CharacterSet.decimalDigits.contains(letter)
			result.append(.init(
				string: String(letter),
				attributes: isDigit ? attributes : nil
			))
		}

		return .init(result)
	}
}
