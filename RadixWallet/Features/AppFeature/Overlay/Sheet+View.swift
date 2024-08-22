import Foundation

// MARK: - Sheet.View
extension Sheet {
	public struct View: SwiftUI.View {
		private let store: StoreOf<Sheet>

		public init(store: StoreOf<Sheet>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					CloseButtonBar {
						store.send(.view(.closeButtonTapped))
					}
					.padding(.horizontal, .small3)

					ScrollView {
						VStack(spacing: .zero) {
							ForEach(viewStore.parts, id: \.self) { part in
								PartView(part: part)
							}
							.environment(\.openURL, openURL)
							.padding(.horizontal, .large2)
						}
						.padding(.top, .small2)
					}
					.animation(.default, value: viewStore.text)
				}
			}
		}

		private var openURL: OpenURLAction {
			OpenURLAction { url in
				if let infoLink = OverlayWindowClient.GlossaryItem(url: url) {
					store.send(.view(.infoLinkTapped(infoLink)))
					return .handled
				} else {
					return .systemAction
				}
			}
		}
	}

	struct PartView: SwiftUI.View {
		let part: Part

		var body: some SwiftUI.View {
			switch part {
			case let .heading2(heading2):
				Text(heading2)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .large2)
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

// MARK: - Sheet.Part
extension Sheet {
	enum Part: Hashable {
		case heading2(String)
		case heading3(String)
		case text(AttributedString)
		case divider
	}
}

extension Sheet.State {
	var parts: [Sheet.Part] {
		Self.parse(string: text)
	}

	private static func parse(string: String) -> [Sheet.Part] {
		var result: [Sheet.Part] = []
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

	private static func nonTextPart(from row: Substring) -> Sheet.Part? {
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
