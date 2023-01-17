#if DEBUG
import SwiftUI

// TODO: improve with variadic generics when available
//
// public struct WithState<Values..., Content: View>: View { [...] }

/// A container view that provides a binding to another view.
///
/// This view is most helpful for creating Xcode previews of views that require bindings.
///
/// For example, if you wanted to create a preview for a text field, you cannot simply introduce
/// some `@State` to the preview since `previews` is static:
///
/// ```swift
/// struct TextField_Previews: PreviewProvider {
///   @State static var text = "" // ⚠️ @State static does not work.
///
///   static var previews: some View {
///     TextField("Test", text: self.$text)
///   }
/// }
/// ```
///
/// So, instead you can use `WithState`:
///
/// ```swift
/// struct TextField_Previews: PreviewProvider {
///   static var previews: some View {
///     WithState1("") { $text in
///       TextField("Test", text: $text)
///     }
///   }
/// }
/// ```
public struct WithState1<Value1, Content: View>: View {
	@State var value1: Value1
	@ViewBuilder let content: (Binding<Value1>) -> Content

	public init(
		_ value1: Value1,
		@ViewBuilder content: @escaping (Binding<Value1>) -> Content
	) {
		self._value1 = State(wrappedValue: value1)
		self.content = content
	}

	public var body: some View {
		self.content($value1)
	}
}

public struct WithState2<Value1, Value2, Content: View>: View {
	@State var value1: Value1
	@State var value2: Value2
	@ViewBuilder let content: (Binding<Value1>, Binding<Value2>) -> Content

	public init(
		_ value1: Value1,
		_ value2: Value2,
		@ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>) -> Content
	) {
		self._value1 = State(wrappedValue: value1)
		self._value2 = State(wrappedValue: value2)
		self.content = content
	}

	public var body: some View {
		self.content($value1, $value2)
	}
}

public struct WithState3<Value1, Value2, Value3, Content: View>: View {
	@State var value1: Value1
	@State var value2: Value2
	@State var value3: Value3
	@ViewBuilder let content: (Binding<Value1>, Binding<Value2>, Binding<Value3>) -> Content

	public init(
		_ value1: Value1,
		_ value2: Value2,
		_ value3: Value3,
		@ViewBuilder content: @escaping (Binding<Value1>, Binding<Value2>, Binding<Value3>) -> Content
	) {
		self._value1 = State(wrappedValue: value1)
		self._value2 = State(wrappedValue: value2)
		self._value3 = State(wrappedValue: value3)
		self.content = content
	}

	public var body: some View {
		self.content($value1, $value2, $value3)
	}
}
#endif
