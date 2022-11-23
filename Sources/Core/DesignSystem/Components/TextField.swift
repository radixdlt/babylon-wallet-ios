import SwiftUI

/*
 func textField(with viewStore: ViewStore) -> some View {
 	VStack(alignment: .leading, spacing: .small2) {
 		TextField(
 			L10n.CreateAccount.placeholder,
 			text: viewStore.binding(
 				get: \.accountName,
 				send: { .textFieldChanged($0) }
 			)
 			.removeDuplicates()
 		)
 		.focused($focusedField, equals: .accountName)
 		.synchronize(
 			viewStore.binding(
 				get: \.focusedField,
 				send: { .textFieldFocused($0) }
 			),
 			self.$focusedField
 		)
 		.padding()
 		.frame(height: .standardButtonHeight)
 		.background(Color.app.gray5)
 		.foregroundColor(.app.gray1)
 		.textStyle(.body1Regular)
 		.cornerRadius(.small2)
 		.overlay(
 			RoundedRectangle(cornerRadius: .small2)
 				.stroke(Color.app.gray1, lineWidth: 1)
 		)

 		Text(L10n.CreateAccount.explanation)
 			.foregroundColor(.app.gray2)
 			.textStyle(.body2Regular)
 	}
 }

 */

/*
 // MARK: - Header
 public struct Tralala {
 	private let placeholderText: String
 	private var text: Binding<String>
 	@FocusState private var focusedField: String

 	public init(
 		placeholderText: String
 	) {
 		self.placeholderText = placeholderText
 	}

 	public var body: some View {
 		VStack(alignment: .leading, spacing: .small2) {
 			TextField(
 				placeholderText,
 				text: text
 			)
 			.removeDuplicates()
 			.focused($focusedField, equals: .accountName)
 			.synchronize(
 				viewStore.binding(
 					get: \.focusedField,
 					send: { .textFieldFocused($0) }
 				),
 				self.$focusedField
 			)
 			.padding()
 			.frame(height: .standardButtonHeight)
 			.background(Color.app.gray5)
 			.foregroundColor(.app.gray1)
 			.textStyle(.body1Regular)
 			.cornerRadius(.small2)
 			.overlay(
 				RoundedRectangle(cornerRadius: .small2)
 					.stroke(Color.app.gray1, lineWidth: 1)
 			)

 			Text(L10n.CreateAccount.explanation)
 				.foregroundColor(.app.gray2)
 				.textStyle(.body2Regular)
 		}
 	}
 }

 // MARK: - Private Computed Properties
 private extension Header {
 }

 #if DEBUG

 // MARK: - TextField_Previews
 struct TextField_Previews: PreviewProvider {
 	static var previews: some View {
 		Tralala()
 	}
 }
 #endif // DEBUG
 */
