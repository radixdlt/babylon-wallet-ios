import Prelude

// MARK: - SecurityQuestionsQuestionProtocol
public protocol SecurityQuestionsQuestionProtocol: Sendable {
	var display: NonEmpty<String> { get }
}

// MARK: - SecurityQuestionsAnswerProtocol
public protocol SecurityQuestionsAnswerProtocol: Sendable {
	var entropy: NonEmpty<Data> { get }
}

// MARK: - SecurityQuestionAnswerToQuestionProtocol
public protocol SecurityQuestionAnswerToQuestionProtocol: Sendable {
	associatedtype Question: SecurityQuestionsQuestionProtocol
	associatedtype Answer: SecurityQuestionsAnswerProtocol
	var question: Question { get }
	var answer: Answer { get }
}

public extension SecurityQuestionAnswerToQuestionProtocol where Self: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.answer.entropy == rhs.answer.entropy && lhs.question.display == rhs.question.display
	}
}

public extension SecurityQuestionAnswerToQuestionProtocol where Self: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.question.display)
		hasher.combine(self.answer.entropy)
	}
}

// MARK: - SecurityQuestionAnswerToQuestionSimple
public struct SecurityQuestionAnswerToQuestionSimple: Sendable, SecurityQuestionAnswerToQuestionProtocol, Hashable {
	public struct Question: SecurityQuestionsQuestionProtocol, Hashable, Identifiable, Codable {
		public var id: String { display.rawValue }
		public let display: NonEmpty<String>
		public init(display: NonEmpty<String>) {
			self.display = display
		}

		public init(from decoder: Decoder) throws {
			let singleValueContainer = try decoder.singleValueContainer()
			let display = try singleValueContainer.decode(NonEmpty<String>.self)
			self.init(display: display)
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(display)
		}
	}

	public struct Answer: SecurityQuestionsAnswerProtocol, Hashable {
		public let entropy: NonEmpty<Data>
		private init(entropy: NonEmpty<Data>) {
			self.entropy = entropy
		}

		public static func from(_ answer: NonEmpty<String>) -> Self {
			.init(entropy: NonEmpty(rawValue: Data(answer.rawValue.trimmed().utf8))!)
		}
	}

	public let question: Question
	public let answer: Answer

	public static func answer(_ answer: NonEmpty<String>, to question: NonEmpty<String>) -> Self {
		Self(question: .init(display: question), answer: .from(answer))
	}
}

/*
 public struct AnswerCandidate: Sendable, Equatable {
     public let display: String
 }

 public struct AnswerOperand: Sendable, Equatable {
     public let title: String
 //    public let answers: [AnswerCandidate]
     public let answers: SecurityQuestion.PossibleAnswers
 }

 public enum FreeformAnswerProcessor: Sendable, Equatable {
     case lowercaseAndTrim
 }

 public struct SecurityQuestion: Sendable, Equatable, Codable {
     public let name: String
     public let version: Int
     public let possibleAnswers: PossibleAnswers
     public init(name: String, version: Int = 1, possibleAnswers: PossibleAnswers) {
         self.name = name
         self.possibleAnswers = possibleAnswers
         self.version = version
     }
     public init(from decoder: Decoder) throws {
     fatalError()
     }
     public func encode(to encoder: Encoder) throws {
         fatalError()
     }
     public static let parentsRendezvous = Self(
         name: "parentsRendezvous",
         possibleAnswers: .structured(
             .product(
                 "In which city and which year did your parents meet?",
                 answerFactors: [
                     .init(title: "City", answers: .freeform(, answerProcessor: )
                 ]
             )
         )
     )
 }
 extension SecurityQuestion {
     public indirect enum PossibleAnswers: Sendable, Equatable {

         case freeform(String, answerProcessor: FreeformAnswerProcessor)
         case structured(Structured)

         public enum Structured: Sendable, Equatable {

             /// E.g. question: "In which city and what year did your parents meet?" is
             /// a **product** kind because the answer space is: `YEAR_COUNT * CITY_COUNT`.
             /// (if one disregards the fact that some cities are new and did not exist
             /// X years ago).
             case product(String, answerFactors: [AnswerOperand])

             /// E.g. question: "Make and model of your first car" is a **sum** kind because
             /// the set of possible models is dependent on the make, the answer space is:
             /// `MODELS_FOR_MAKE_A + MODELS_FOR_MAKE_B + MODELS_FOR_MAKE_C ...`, thus harder
             /// to implement and calculate entropy for.
             case sum(String, answerTerms: [AnswerOperand])
         }
     }
 }
     */

/*
 // MARK: - SecurityQuestionPossibleAnswerPartProtocol
 public protocol SecurityQuestionPossibleAnswerPartProtocol: Sendable, Hashable, Codable {
 	associatedtype Value: Sendable & Hashable & Codable = NonEmpty<String>
 	associatedtype Display: Sendable & Hashable & Codable = Value
 	var value: Value { get }
 	var display: Display { get }
 	init(value: Value, display: Display)
 }

 extension SecurityQuestionPossibleAnswerPartProtocol where Display == Value {
 	public var display: Display { value }
 	init(value: Value) {
 		self.init(value: value, display: value)
 	}
 }

 // MARK: - SecurityQuestionPossibleAnswerProtocolBase
 public protocol SecurityQuestionPossibleAnswerProtocolBase: Sendable {
 	func isEqualTo(other: SecurityQuestionPossibleAnswerProtocolBase) -> Bool
 	func hashIntoHasher(_ hasher: inout Hasher)
 }

 // MARK: - SecurityQuestionPossibleAnswerProtocol
 public protocol SecurityQuestionPossibleAnswerProtocol: SecurityQuestionPossibleAnswerProtocolBase, Hashable, Codable {
 	associatedtype Display: Sendable & Hashable & Codable = NonEmpty<String>
 	var display: Display { get }

 	associatedtype Part: SecurityQuestionPossibleAnswerPartProtocol
 	var parts: NonEmpty<OrderedSet<Part>> { get }
 }

 public extension SecurityQuestionPossibleAnswerProtocol {
 	func isEqualTo(other anyOther: SecurityQuestionPossibleAnswerProtocolBase) -> Bool {
 		guard let other = anyOther as? Self else { return false }
 		return other == self
 	}

 	func hashIntoHasher(_ hasher: inout Hasher) {
 		hasher.combine(self)
 	}
 }

 // MARK: - SecurityQuestionProtocol
 public protocol SecurityQuestionProtocol: Sendable, Equatable, Codable {
 	associatedtype PossibleAnswer: SecurityQuestionPossibleAnswerProtocol
 	var version: Int { get }
 	var question: NonEmpty<String> { get }
 	var possibleAnswers: NonEmpty<OrderedSet<PossibleAnswer>> { get }
 	static var bundled: Self { get }
 }

 // MARK: - SecurityQuestion
 public enum SecurityQuestion: Sendable, Hashable, Codable {
 	/// "Make and model of your first car?"
 	case firstCar(FirstCar)
 }

 // MARK: SecurityQuestion.FirstCar
 public extension SecurityQuestion {
 	struct FirstCar: SecurityQuestionProtocol, Hashable, Codable {
 		public let version: Int
 		public let question: NonEmpty<String>
 		public let possibleAnswers: NonEmpty<OrderedSet<PossibleAnswer>>

 		public struct PossibleAnswer: SecurityQuestionPossibleAnswerProtocol {
 			public struct Part: SecurityQuestionPossibleAnswerPartProtocol, ExpressibleByStringLiteral {
 				public typealias Value = NonEmpty<String>
 				public let value: Value
 				public init(value: Value, display _: Display) {
 					self.value = value
 				}
 			}

 			public typealias Display = NonEmpty<String>
 			public let display: Display
 			public let parts: NonEmpty<OrderedSet<Part>>
 		}

 		public static let bundled: Self = .init(
 			version: 1,
 			question: "Make and model of your first car?",
 			possibleAnswers: .init(
 				rawValue: .init([
 					.init(
 						display: "Make",
 						parts: .init(rawValue: .init([
 							"Audi",
 							"BMW",
 						]))!
 					),
 				])
 			)!
 		)
 	}
 }

 public extension SecurityQuestionPossibleAnswerPartProtocol where Self.Display == Self.Value, Self.Value == NonEmpty<String>, Self: ExpressibleByStringLiteral {
 	init(stringLiteral: String) {
 		precondition(!stringLiteral.isEmpty)
 		self.init(value: NonEmpty(rawValue: stringLiteral)!)
 	}
 }

 public typealias AnswersToSecurityQuestions = NonEmpty<OrderedSet<AnswerToSecurityQuestion>>

 // MARK: - AnswerToSecurityQuestion
 public struct AnswerToSecurityQuestion: Sendable, Hashable {
 	public static func == (lhs: Self, rhs: Self) -> Bool {
 		lhs.question == rhs.question && lhs.answer.isEqualTo(other: rhs.answer)
 	}

 	public func hash(into hasher: inout Hasher) {
 		hasher.combine(self.question)
 		self.answer.hashIntoHasher(&hasher)
 	}

 	public let question: SecurityQuestion
 	public let answer: SecurityQuestionPossibleAnswerProtocolBase
 }
 */
