extension AddressDetails.State {
	var viewState: AddressDetails.ViewState {
		.init(
			address: address,
			title: title,
			qrImage: qrImage,
			showEnlarged: showEnlarged,
			showShare: showShare
		)
	}
}

// MARK: - AddressDetails.View

public extension AddressDetails {
	struct ViewState: Equatable {
		let address: LedgerIdentifiable.Address
		let colorisedAddress: AttributedString
		let enlargedAddress: AttributedString
		let title: Loadable<String?>
		let qrImage: Loadable<CGImage>
		let showEnlarged: Bool
		let showShare: Bool

		init(address: LedgerIdentifiable.Address, title: Loadable<String?>, qrImage: Loadable<CGImage>, showEnlarged: Bool, showShare: Bool) {
			self.address = address
			self.colorisedAddress = Self.colorised(address: address)
			self.enlargedAddress = Self.enlarged(address: address)
			self.title = title
			self.qrImage = qrImage
			self.showEnlarged = showEnlarged
			self.showShare = showShare
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AddressDetails>

		public init(store: StoreOf<AddressDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				content(viewStore)
					.withNavigationBar {
						viewStore.send(.closeButtonTapped)
					}
					.presentationDetents([.large])
					.presentationDragIndicator(.visible)
					.task {
						viewStore.send(.task)
					}
					.sheet(isPresented: viewStore.binding(get: \.showShare, send: .shareDismissed)) {
						ShareView(items: [viewStore.address.address])
					}
			}
		}

		private func content(_ viewStore: ViewStoreOf<AddressDetails>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				top(title: viewStore.title, showQrCode: viewStore.showQrCode, qrImage: viewStore.qrImage)

				fullAddress(address: viewStore.colorisedAddress)
					.padding(.vertical, .medium3)

				bottom(showVerifyOnLedger: viewStore.showVerifyOnLedger)

				Spacer()
			}
			.multilineTextAlignment(.center)
			.padding([.horizontal, .bottom], .medium3)
			.overlay(alignment: .top) {
				Group {
					if viewStore.showEnlarged {
						enlargedView(text: viewStore.enlargedAddress)
					}
				}
				.animation(.easeInOut, value: viewStore.showEnlarged)
			}
		}

		private func top(title: Loadable<String?>, showQrCode: Bool, qrImage: Loadable<CGImage>) -> some SwiftUI.View {
			VStack(spacing: .small2) {
				loadable(title) {
					ProgressView()
				} successContent: { title in
					Text(title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
				}

				if showQrCode {
					Text(L10n.AddressDetails.qrCode)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)

					qrCode(qrImage: qrImage)
						.padding(.horizontal, .large2)
				}
			}
		}

		private func fullAddress(address: AttributedString) -> some SwiftUI.View {
			VStack(spacing: .medium2) {
				VStack(spacing: .small2) {
					Text(L10n.AddressDetails.fullAddress)
						.foregroundColor(.app.gray1)
					Text(address)
				}
				actions
			}
			.textStyle(.body1Header)
			.padding(.vertical, .medium1)
			.padding(.horizontal, .medium3)
			.background(Color.app.gray5)
			.cornerRadius(.small1)
		}

		private var actions: some SwiftUI.View {
			HStack(spacing: .large3) {
				Button(L10n.AddressDetails.copy, image: .copy) {
					store.send(.view(.copyButtonTapped))
				}
				Button(L10n.AddressDetails.enlarge, image: .fullScreen) {
					store.send(.view(.enlargeButtonTapped))
				}
				Button(L10n.AddressDetails.share, systemImage: "square.and.arrow.up") {
					store.send(.view(.shareButtonTapped))
				}
			}
			.padding(.horizontal, .medium2)
			.foregroundColor(.app.gray1)
		}

		private func bottom(showVerifyOnLedger: Bool) -> some SwiftUI.View {
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
				if showVerifyOnLedger {
					Button(L10n.AddressDetails.verifyOnLedger) {
						store.send(.view(.verifyOnLedgerButtonTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
			}
		}

		private func qrCode(qrImage: Loadable<CGImage>) -> some SwiftUI.View {
			ZStack {
				switch qrImage {
				case let .success(value):
					Image(decorative: value, scale: 1)
						.resizable()
						.aspectRatio(1, contentMode: .fit)
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
			.animation(.easeInOut, value: qrImage.isSuccess)
		}
	}
}

// MARK: - Enlarged view
private extension AddressDetails.View {
	func enlargedView(text: AttributedString) -> some SwiftUI.View {
		Group {
			Text(text)
				.textStyle(.enlarged)
				.foregroundColor(.app.white)
		}
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
			.contentShape(Rectangle())
			.onTapGesture {
				store.send(.view(.hideEnlargedView))
			}
	}
}

private extension AddressDetails.ViewState {
	static func colorised(address: LedgerIdentifiable.Address) -> AttributedString {
		let raw = address.formatted(.raw)
		var result = AttributedString(raw, foregroundColor: .app.gray2)

		let truncatedParts: [String] =
			switch address {
			case let .nonFungibleGlobalID(globalId):
				[globalId.resourceAddress.formatted(.default), globalId.localID.formatted(.default)]
			default:
				[address.formatted(.default)]
			}

		for part in truncatedParts {
			let boldChars = part.split(separator: "...")
			if let range = result.range(of: boldChars[0]) {
				result[range].foregroundColor = .app.gray1
			}
			if boldChars.count == 2, let range = result.range(of: boldChars[1], options: .backwards) {
				result[range].foregroundColor = .app.gray1
			}
		}

		return result
	}

	static func enlarged(address: LedgerIdentifiable.Address) -> AttributedString {
		let attributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.app.green3)]
		let result = NSMutableAttributedString()
		for letter in address.address.unicodeScalars {
			let isDigit = CharacterSet.decimalDigits.contains(letter)
			result.append(.init(
				string: String(letter),
				attributes: isDigit ? attributes : nil
			))
		}

		return .init(result)
	}

	var showQrCode: Bool {
		switch address {
		case .account:
			true
		default:
			false
		}
	}

	var showVerifyOnLedger: Bool {
		switch address {
		case let .account(_, isLedgerHWAccount):
			isLedgerHWAccount
		default:
			false
		}
	}
}
