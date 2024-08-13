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
					HStack(spacing: .zero) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}

						Spacer()
					}
					.padding(.horizontal, .medium3)

					ForEachStatic(viewStore.parts) { part in
						PartView(part: part)
					}
					.environment(\.openURL, openURL)
					.padding(.horizontal, .large2)

					Spacer()
				}
				.padding(.top, .medium3)
				.animation(.default, value: viewStore.state)
			}
		}

		private var openURL: OpenURLAction {
			OpenURLAction { url in
				if let infoLink = OverlayWindowClient.InfoLink(url: url) {
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
			case let .heading1(heading1):
				Text(heading1)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium3)
			case let .heading2(heading2):
				Text(heading2)
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium3)
			case let .heading3(heading3):
				Text(heading3)
					.textStyle(.body2Header)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.bottom, .medium3)
			case let .text(text):
				Text(text)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.leading)
					.flushedLeft
					.padding(.bottom, .large2)
			}
		}
	}
}

// MARK: - Sheet.Part
extension Sheet {
	enum Part {
		case heading1(String)
		case heading2(String)
		case heading3(String)
		case text(AttributedString)
	}
}

extension Sheet.State {
	private func heading(from row: Substring) -> Sheet.Part? {
		if row.hasPrefix("# ") {
			.heading1(String(row.dropFirst(2)))
		} else if row.hasPrefix("## ") {
			.heading2(String(row.dropFirst(3)))
		} else if row.hasPrefix("### ") {
			.heading3(String(row.dropFirst(4)))
		} else {
			nil
		}
	}

	var parts: [Sheet.Part] {
		var result: [Sheet.Part] = []
		var currentText = ""

		func addCurrentText() {
			if !currentText.isEmpty {
				result.append(.text(currentText.markdownAttributed))
				currentText = ""
			}
		}

		for row in text.split(separator: "\n", omittingEmptySubsequences: false) {
			if let heading = heading(from: row) {
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
}

extension String {
	var markdownAttributed: AttributedString {
		(try? AttributedString(markdown: self, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? .init(self)
	}
}
