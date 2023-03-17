import ComposableArchitecture
@_spi(Validation) import Prelude
import SwiftUI

extension Binding {
	@_disfavoredOverload
	public static func validation<Value, Error>(
		_ validation: Binding<Validation<Value, Error>>
	) -> Binding<Value?> {
		.init(
			get: { validation.wrappedValue.rawValue },
			set: { validation.wrappedValue.wrappedValue = $0 }
		)
	}

	public static func validation<Error>(
		_ validation: Binding<Validation<String, Error>>
	) -> Binding<String> {
		.validation(validation) ?? ""
	}
}

extension Binding {
	public subscript<V, Error, T>(
		dynamicMember keyPath: KeyPath<Validated<V, Error>, T?>
	) -> T? where Value == Validation<V, Error> { wrappedValue.projectedValue?[keyPath: keyPath] }
}

#if DEBUG
struct ValidationBindingPreviews: PreviewProvider {
	@MainActor
	struct ValidationBindingView: View {
		@State
		@Validation<String, String>(
			onNil: "Cannot be nil",
			rules: [
				.if(\.isEmpty, error: "Cannot be empty"),
				.if(\.isBlank, error: "Cannot be blank"),
			]
		)
		private var name: String? = nil

		var body: some View {
			VStack(alignment: .leading) {
				TextField(
					"Name",
					text: .validation($name),
					prompt: Text("Name")
				)
				.textFieldStyle(.roundedBorder)

				if let errors = $name.errors {
					Text(errors.first)
						.foregroundColor(.red)
						.font(.footnote)
				}
			}
			.padding()
		}
	}

	static var previews: some View {
		ValidationBindingView()
	}
}
#endif
