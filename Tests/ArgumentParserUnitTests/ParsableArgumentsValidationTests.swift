//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
@testable import ArgumentParser

final class ParsableArgumentsValidationTests: XCTestCase {
  private struct A: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    enum CodingKeys: String, CodingKey {
      case count
      case phrase
    }
    
    func run() throws {}
  }
  
  private struct B: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    func run() throws {}
  }
  
  private struct C: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    enum CodingKeys: String, CodingKey {
      case phrase
    }
    
    func run() throws {}
  }
  
  private struct D: ParsableArguments {
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    enum CodingKeys: String, CodingKey {
      case count
    }
  }
  
  private struct E: ParsableArguments {
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter: Bool
    
    enum CodingKeys: String, CodingKey {
      case count
    }
  }
  
  func testCodingKeyValidation() throws {
    try ParsableArgumentsCodingKeyValidator.validate(A.self)
    
    try ParsableArgumentsCodingKeyValidator.validate(B.self)
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(C.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["count"])
      } else {
        XCTFail()
      }
    }
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(D.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["phrase"])
      } else {
        XCTFail()
      }
    }
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(E.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["phrase", "includeCounter"])
      } else {
        XCTFail()
      }
    }
  }
  
  private struct F: ParsableArguments {
    @Argument()
    var phrase: String
    
    @Argument()
    var items: [Int]
  }
  
  private struct G: ParsableArguments {
    @Argument()
    var items: [Int]
    
    @Argument()
    var phrase: String
  }
  
  private struct H: ParsableArguments {
    @Argument()
    var items: [Int]
    
    @Option()
    var option: Bool
  }
  
  private struct I: ParsableArguments {
    @Argument()
    var name: String
    
    @OptionGroup()
    var options: F
  }
  
  private struct J: ParsableArguments {
    struct Options: ParsableArguments {
      @Argument()
      var numberOfItems: [Int]
    }
    
    @OptionGroup()
    var options: Options
    
    @Argument()
    var phrase: String
  }
  
  private struct K: ParsableArguments {
    struct Options: ParsableArguments {
      @Argument()
      var items: [Int]
    }
    
    @Argument()
    var phrase: String
    
    @OptionGroup()
    var options: Options
  }
  
  func testPositionalArgumentsValidation() throws {
    try PositionalArgumentsValidator.validate(A.self)
    try PositionalArgumentsValidator.validate(F.self)
    XCTAssertThrowsError(try PositionalArgumentsValidator.validate(G.self)) { error in
      if let error = error as? PositionalArgumentsValidator.Error {
        XCTAssert(error.positionalArgumentFollowingRepeated == "phrase")
        XCTAssert(error.repeatedPositionalArgument == "items")
      } else {
        XCTFail()
      }
      XCTAssert(error is PositionalArgumentsValidator.Error)
    }
    try PositionalArgumentsValidator.validate(H.self)
    try PositionalArgumentsValidator.validate(I.self)
    XCTAssertThrowsError(try PositionalArgumentsValidator.validate(J.self)) { error in
      if let error = error as? PositionalArgumentsValidator.Error {
        XCTAssert(error.positionalArgumentFollowingRepeated == "phrase")
        XCTAssert(error.repeatedPositionalArgument == "numberOfItems")
      } else {
        XCTFail()
      }
      XCTAssert(error is PositionalArgumentsValidator.Error)
    }
    try PositionalArgumentsValidator.validate(K.self)
  }

  private struct DifferentNames: ParsableArguments {
    @Option()
    var foo: String

    @Option()
    var bar: String
  }

  struct TwoOfTheSameName: ParsableCommand {
    @Option()
    var foo: String

    @Option(name: .customLong("foo"))
    var notActuallyFoo: String
  }

  private struct MultipleUniquenessViolations: ParsableArguments {
    @Option()
    var foo: String

    @Option(name: .customLong("foo"))
    var notActuallyFoo: String

    @Option()
    var bar: String

    @Flag(name: .customLong("bar"))
    var notBar: Bool

    @Option()
    var help: String
  }

  private struct MultipleNamesPerArgument: ParsableCommand {
    @Flag(name: [.customShort("v"), .customLong("very-chatty")])
    var verbose: Bool

    enum Versimilitude: String, ExpressibleByArgument {
      case yes
      case some
      case none
    }

    @Option(name: .customShort("v"))
    var versimilitude: Versimilitude
  }

  private struct FourDuplicateNames: ParsableArguments {
    @Option()
    var foo: String

    @Option(name: .customLong("foo"))
    var notActuallyFoo: String

    @Flag(name: .customLong("foo"))
    var stillNotFoo: Bool

    enum Numbers: Int, ExpressibleByArgument {
      case one = 1
      case two
      case three
    }

    @Option(name: .customLong("foo"))
    var alsoNotFoo: Numbers
  }

  private let unexpectedErrorMessage = "Expected error of type `ParsableArgumentsUniqueNamesValidator.Error`, but got something else."

  func testUniqueNamesValidation_NoViolation() throws {
    XCTAssertNoThrow(try ParsableArgumentsUniqueNamesValidator.validate(DifferentNames.self))
  }

  func testUniqueNamesValidation_TwoOfSameName() throws {
    XCTAssertThrowsError(try ParsableArgumentsUniqueNamesValidator.validate(TwoOfTheSameName.self)) { error in
      if let error = error as? ParsableArgumentsUniqueNamesValidator.Error {
        XCTAssertEqual(error.description, "Multiple (2) `Option` or `Flag` arguments are named \"foo\".")
      } else {
        XCTFail(unexpectedErrorMessage)
      }
    }
  }

  func testUniqueNamesValidation_TwoDuplications() throws {
    XCTAssertThrowsError(try ParsableArgumentsUniqueNamesValidator.validate(MultipleUniquenessViolations.self)) { error in
      if let error = error as? ParsableArgumentsUniqueNamesValidator.Error {
        XCTAssert(
          /// The `Mirror` reflects the properties `foo` and `bar` in a random order, but `help` will always be first
          /// because the `Error`s `violations` array is built that way.
          error.description == """
          Multiple (2) `Option` or `Flag` arguments are named \"bar\".
          Multiple (2) `Option` or `Flag` arguments are named \"foo\".
          """
          || error.description == """
          Multiple (2) `Option` or `Flag` arguments are named \"foo\".
          Multiple (2) `Option` or `Flag` arguments are named \"bar\".
          """
        )
      } else {
        XCTFail(unexpectedErrorMessage)
      }
    }
  }

  func testUniqueNamesValidation_ArgumentHasMultipleNames() throws {
    XCTAssertThrowsError(try ParsableArgumentsUniqueNamesValidator.validate(MultipleNamesPerArgument.self)) { error in
      if let error = error as? ParsableArgumentsUniqueNamesValidator.Error {
        XCTAssertEqual(error.description, "Multiple (2) `Option` or `Flag` arguments are named \"v\".")
      } else {
        XCTFail(unexpectedErrorMessage)
      }
    }
  }

  func testUniqueNamesValidation_MoreThanTwoDuplications() throws {
    XCTAssertThrowsError(try ParsableArgumentsUniqueNamesValidator.validate(FourDuplicateNames.self)) { error in
      if let error = error as? ParsableArgumentsUniqueNamesValidator.Error {
        XCTAssertEqual(error.description, "Multiple (4) `Option` or `Flag` arguments are named \"foo\".")
      } else {
        XCTFail(unexpectedErrorMessage)
      }
    }
  }
}
