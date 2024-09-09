import Foundation

// MARK: - InfoLinkSheet.View
extension InfoLinkSheet {
	public struct View: SwiftUI.View {
		@SwiftUI.State private var showTitle: Bool = false
		private let store: StoreOf<InfoLinkSheet>

		private let showTitleOffset: CGFloat = 40

		private let hideTitleOffset: CGFloat = 47

		private let coordSpace: String = "InfoLinkSheet"

		private let scrollViewTopID = "scrollViewTopID"

		private var openURL: OpenURLAction {
			OpenURLAction { url in
				if let infoLink = InfoLinkSheet.GlossaryItem(url: url) {
					store.send(.view(.infoLinkTapped(infoLink)))
					return .handled
				} else {
					return .systemAction
				}
			}
		}

		public init(store: StoreOf<InfoLinkSheet>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollViewReader { proxy in
					ScrollView {
						VStack(spacing: .zero) {
							if let image = viewStore.image {
								Image(asset: image)
									.resizable()
									.frame(.veryLarge)
									.padding(.bottom, .medium2)
							}

							let parts = viewStore.parts
							ForEach(parts, id: \.self) { part in
								PartView(part: part)
									.measurePosition(part == parts.first ? scrollViewTopID : nil, coordSpace: coordSpace)
							}
							.environment(\.openURL, openURL)
							.padding(.horizontal, .large2)
						}
						.padding(.top, .small2)
						.id(scrollViewTopID)
					}
					.coordinateSpace(name: coordSpace)
					.animation(.default.speed(2), value: viewStore.text)
					.onChange(of: viewStore.text) { _ in
						withAnimation {
							proxy.scrollTo(scrollViewTopID, anchor: .top)
						}
					}
					.onPreferenceChange(PositionsPreferenceKey.self) { rects in
						guard let offset = rects[scrollViewTopID]?.maxY else { return }
						if !showTitle, offset < showTitleOffset {
							showTitle = true
						} else if showTitle, offset > hideTitleOffset {
							showTitle = false
						}
					}
				}
				.navigationBarTitleDisplayMode(.inline)
				.navigationTitle(showTitle ? viewStore.title : "")
			}
		}
	}
}

// MARK: - InfoLinkSheet.PartView
extension InfoLinkSheet {
	struct PartView: SwiftUI.View {
		let part: Part

		var body: some SwiftUI.View {
			switch part {
			case let .heading2(heading2):
				Text(heading2)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .large1)
			case let .heading3(heading3):
				Text(heading3)
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium3)
			case let .text(text):
				Text(text)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.tint(.app.blue2)
					.multilineTextAlignment(.leading)
					.flushedLeft
					.padding(.bottom, .small3)
			case .divider:
				Separator()
					.padding(.top, .small1)
					.padding(.horizontal, -.small2)
					.padding(.bottom, .large2)
			}
		}
	}
}

// MARK: - InfoLinkSheet.Part
extension InfoLinkSheet {
	enum Part: Hashable {
		case heading2(String)
		case heading3(String)
		case text(AttributedString)
		case divider
	}
}

extension InfoLinkSheet.State {
	var title: String {
		text.split(separator: "\n", omittingEmptySubsequences: false).first.flatMap(Self.title) ?? ""
	}

	var parts: [InfoLinkSheet.Part] {
		Self.parse(string: text)
	}

	private static func parse(string: String) -> [InfoLinkSheet.Part] {
		var result: [InfoLinkSheet.Part] = []
		var currentText = ""

		func addCurrentText() {
			if !currentText.isEmpty {
				result.append(.text(currentText.markdownAttributed))
				currentText = ""
			}
		}

		for row in string.split(separator: "\n", omittingEmptySubsequences: false) {
			if let heading = nonTextPart(from: row) {
				addCurrentText()
				result.append(heading)
			} else {
				if !currentText.isEmpty {
					currentText.append("\n")
				}
				currentText.append(String(row))
			}
		}

		addCurrentText()

		return result
	}

	private static func title(in row: Substring) -> String? {
		guard case let .heading2(heading) = nonTextPart(from: row) else { return nil }
		return heading
	}

	private static func nonTextPart(from row: Substring) -> InfoLinkSheet.Part? {
		if row.hasPrefix("## ") {
			.heading2(String(row.dropFirst(3)))
		} else if row.hasPrefix("### ") {
			.heading3(String(row.dropFirst(4)))
		} else if row.hasPrefix("---") {
			.divider
		} else {
			nil
		}
	}
}

extension String {
	var markdownAttributed: AttributedString {
		(try? AttributedString(markdown: self, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? .init(self)
	}
}
