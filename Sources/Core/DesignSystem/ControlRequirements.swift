import Either
import Prelude
import SwiftUI

// MARK: - WithControlRequirements
// TODO: simplify with variadic generics in the future
//
// public struct WithControlRequirements<Control: View>: View {
//     [...]
//
//     public init<T...>(
//         _ requirements: @autoclosure () -> T?...,
//         forAction action: @escaping (T...) -> Void,
//         @ViewBuilder control: (@escaping () -> Void) -> Control
//     ) {
//         [...]
//     }
// }

public struct WithControlRequirements<Control: View>: View {
	@Environment(\.controlState) var controlState

	let action: (() -> Void)?
	let control: Control

	public init<A>(
		_ a: @autoclosure () -> A?,
		forAction action: @escaping (A) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = {
			if let a = a() {
				return { action(a) }
			} else {
				return nil
			}
		}()
		self.action = action
		self.control = control(action ?? {})
	}

	public init<A, B>(
		_ a: @autoclosure () -> A?,
		_ b: @autoclosure () -> B?,
		forAction action: @escaping (A, B) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = {
			if let a = a(), let b = b() {
				return { action(a, b) }
			} else {
				return nil
			}
		}()
		self.action = action
		self.control = control(action ?? {})
	}

	public init<A, B>(
		_ a: @autoclosure () -> A?,
		or b: @autoclosure () -> B?,
		forAction action: @escaping (Either<A, B>) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let controlAction: (() -> Void)? = {
			if let a = a() {
				return { action(.left(a)) }
			}

			if let b = b() {
				return { action(.right(b)) }
			}

			return nil
		}()
		self.action = controlAction
		self.control = control(controlAction ?? {})
	}

	public init<A, B, C>(
		_ a: @autoclosure () -> A?,
		_ b: @autoclosure () -> B?,
		_ c: @autoclosure () -> C?,
		forAction action: @escaping (A, B, C) -> Void,
		@ViewBuilder control: (@escaping () -> Void) -> Control
	) {
		let action: (() -> Void)? = {
			if let a = a(), let b = b(), let c = c() {
				return { action(a, b, c) }
			} else {
				return nil
			}
		}()
		self.action = action
		self.control = control(action ?? {})
	}

	public var body: some View {
		control.controlState(action == nil ? .disabled : controlState)
	}
}

#if DEBUG
import struct SwiftUINavigation.WithState

struct WithControlRequirements_Previews: PreviewProvider {
	static var previews: some View {
		WithState(initialValue: "") { $name in
			Form {
				TextField("Name", text: $name, prompt: Text("Name"))
			}
			.safeAreaInset(edge: .bottom, spacing: .zero) {
				WithControlRequirements(
					name.nilIfBlank,
					forAction: { name in loggerGlobal.debug("Hello \(name)!") }
				) { action in
					Button("Submit", action: action)
						.buttonStyle(.primaryRectangular)
						.padding()
				}
			}
		}
	}
}
#endif
