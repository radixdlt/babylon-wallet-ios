import SwiftUI

/// A helper view that allows to show a placeholder on the `TextEditor` while the content is empty.
///
/// This is a workaround while Apple doesn't provide a way of setting the placeholder on the native view.
struct AppTextEditor: View {
	let placeholder: String
	@Binding var text: String

	var body: some View {
		ZStack(alignment: .topLeading) {
			if text.isEmpty {
				Text(placeholder)
					.padding(.top, 10)
					.padding(.leading, 6)
					.disabled(true)
					.foregroundColor(.secondaryText)
			}

			TextEditor(text: $text)
		}
	}
}
