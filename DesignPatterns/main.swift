//
//  main.swift
//  DesignPatterns
//
//  Created by Orland Tompkins on 2/01/23.
//

import Foundation

// MARK: - Futures, Promises, and Reactive Programming
 /** Closure and memory management
 -Closure closes over the variables and constants it refers from the enclosing context
 */

///*
import Dispatch
struct Book {
    var title: String
    var author: String
    var price: Double
}

func sellBook(_ book: Book) -> () -> Double {
    var totalSales = 0.0
    func sell() -> Double {
        totalSales += book.price
        return totalSales
    }
    return sell
}

let bookA = Book(title: "BookA", author: "AuthorA", price: 10.0)
let bookB = Book(title: "BookB", author: "AuthorB", price: 13.0)
let sellBookA = sellBook(bookA)
let sellBookB = sellBook(bookB)
print("book sales for: \(sellBookA())")
print("book sales for: \(sellBookB())")

// Removing @escaping will trigger compiler complaint
func delay(_ d: Double, fn: @escaping () -> ()) {
    DispatchQueue.global().asyncAfter(deadline: .now() + d) {
        DispatchQueue.main.async {
            fn()
        }
    }
}

// Breaking the Cyclic Dependencies
class OpertionJuggler {
    /** Retain cycle
     -Stores closure created by addOperation in its operations property
     -Refers self, so it holds a strong reference, but the operations array, which is strongly referenced by self, also takes a strong reference to the closure
     -Preceding code will compile, Xcode Analyze command is not able to detect the cycle, however. App may crash at runtime due to its memory footprint
     */
    
    private var operations: [() -> Void] = []
    var delay = 1.0
    var name = ""
    init(name: String) {
        self.name = name
    }
    func addOperation(op: (@escaping ()->Void)) {
        self.operations.append { [weak self] () in
            if let sself = self {
                DispatchQueue.global().asyncAfter(deadline: .now() + sself.delay) {
                    op()
                }
            }
        }
    }
    func runLastOperation(index: Int) {
        self.operations.last!()
    }
}

/**
class ViewController: UIViewController {
    /** Shows retain cycle */
    var opJ = OperationJuggler(name: "first")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        opJ.addOperation {
            print("Executing operation 1")
        }
        self. opJ.runLastOperation(index: 0)
    }
    // Release the previous OperationJuggler
    self.opJ = OperationJuggler(name: "replacement")
}
 */

class OperationJugglerr {
    /** Removing the retain cycle */
    private var operations : [() -> Void] = []
    var delay = 1.0
    var name = ""
    init(name: String) {
        self.name = name
    }
    func addOperation(op: (@escaping ()->Void)) {
        self.operations.append { [weak self] in
            guard let self = self else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + self.delay) {
                op()
            }
        }
    }
    func runLastOperation(index: Int) {
        self.operations.last!()
    }
    deinit {
        self.delay = -1.0
        print("Juggler named " + self.name + " DEINITIED")
    }
}

class IncrementJuggler {
    /** Retain cycle would ensue just the same */
    private var incrementValues : [(Int) -> Int] = []
    var baseValue = 100
    
    func addValue(increment: Int) {
        self.incrementValues.append { (increment) -> Int in
            return self.baseValue + increment
        }
    }
    func runOperation(index: Int) {
        //...
    }
}

// Future and promises under the hood

public enum Result<Value> {
    case success(Value)
    case failure(Error)
}

enum SimpleError: Error {
    case errorCause1
    case errorCause2
}

typealias Callback<T> = (Result<T>) -> Void

/**
 -Future represent read-only
 -Promise responsible for resolving success or failure
 */

public class Future<T> {
    internal var result : Result<T>? {
        didSet {
            if let result = result, let callback = callback {
                callback(result)
            }
        }
    }
    var callback : Callback<T>?
    init(_ callback: Callback<T>? = nil) {
        self.callback = callback
    }
    func then(_ callback: @escaping Callback<T>) {
        self.callback = callback
        if let result = result {
            callback(result)
        }
    }
}

public final class Promise<T> : Future<T> {
    func resolve(_ value: T) {
        result = .success(value)
    }
    func reject(_ error: Error) {
        result = .failure(error)
    }
}

func asyncOperation1(_ delay: Double) -> Promise<String> {
    /** Does NOT prevent callback hell */
    let promise = Promise<String>()
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        DispatchQueue.main.async {
            print("asyncoperation1 Completed")
            promise.result = .success("Test Result")
        }
    }
    return promise
}

let future : Future<String> = asyncOperation1(1.0)
future.then { result in
    switch (result) {
        case .success(let value) :
            print(" Handling result: \(value) ")
        case .failure(let error):
            print(" Handling error: \(error) ")
    }
}

/**
 OUTPUT:
 aSyncoperation 1 Completed
    Handling result: Test Result
 */

extension Future {
    func chain<U>(_ cbk: @escaping (T) -> Future<U>) -> Future<U> {
        let p = Promise<U>()
        self.then { result in
            switch result {
                case .success(let value) : cbk(value).then { r in p.result = r }
                case .failure(let error) : p.result = .failure(error)
            }
        }
        return p
    }
}

func asyncOperation2 () -> Promise<String> {
    let promise = Promise<String>()
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
        DispatchQueue.main.async {
            print("asynOperation2 completed")
            promise.resolve("Test Result")
        }
    }
    return promise
}

func asyncOperation3(_ str : String) -> Promise<Int> {
    let promise = Promise<Int>()
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
        DispatchQueue.main.async {
            print("asyncOperation3 completed")
            promise.resolve(1000)
        }
    }
    return promise
}

func asyncOperation4(_ input : Int) -> Promise<Double> {
    let promise = Promise<Double>()
    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
        DispatchQueue.main.async {
            print("asyncOperation4 completed")
            promise.reject(SimpleError.errorCause1)
        }
    }
    return promise
}

let promise2 = asyncOperation2()
promise2.chain { result in
    return asyncOperation3(result)
}.chain { result in
    return asyncOperation4(result)
}.then { result in
    print("THEN: \(result)")
}

// Reactive programming
/** !! Skipped !! */

// MARK: - Dependency Injection Pattern - Incomplete
/**
 -Creating a maintainable and testable system
 */

/** Constructor Injection */
protocol BasketStore {
    func loadAllProduct() -> [Product]
    func add(product: Product)
    func delete(product: Product)
}

protocol BasketService {
    func fetchAllProduct(onSuccess: ([Product]) -> Void )
    func append(product: Product)
    func remove(product: Product)
}

struct Product {
    let id: String
    let name: String
    //...
}

class BasketClient {
    private let service: BasketService
    private let store: BasketStore
    init(service: BasketService, store: BasketStore) {
        self.service = service
        self.store = store
    }
    
    func add(product: Product) {
        store.add(product: product)
        service.append(product: product)
        calculateAppliedDiscount()
        //...
    }
    //...
    private func calculateAppliedDiscount() {
        //...
    }
}

class NSPersistentStore: NSObject {
    init(persistentStoreCoordinator root: NSPersistentStoreCoordinator?,
         configurationName name: String?,
         URL url: NSURL,
         options: [NSObject: AnyObject]?)
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? { get }
}

// MARK: - MVVM Pattern - Incomplete

/** Model */
// Question.swift
enum BooleanAnswer: String {
    case `true`
    case `false`
}

struct Question {
    let question: String
    let answer: BooleanAnswer
}

extension Question {
    func isGoodAnswer(result: String?) -> Bool {
        return result == answer.rawValue
    }
}

// QuestionController.swift
class QuestionController {
    private var questions = [Question]()
    
    func load() { /* load from disk, memor or else */ }
    
    // Get the next question, if available
    func next() -> Question? {
        return questions.popLast()
    }
}

/** ViewModel
 -Provide a usable representation of the Model to the View layer
 -Provide a way to BIND itself to events using closures in order to attach the callbacks to ViewModel
 */

class ViewModel {
    private let questions = QuestionController()
    private var currentQuestion: Question? = nil {
        didSet { onQuestionChanged?() }
    }
    var onQuestionChanged: (() -> Void)?
    var onAnswer: ((Bool) -> Void)?
    
    func getQuestionText() -> String? {
        return currentQuestion?.question
    }
    
    func start() {
        while let question = nextQuestion() {
            waitForAnswer(question: question)
        }
    }
    private func waitForAnswer(question: Question) {
        let result = readLine()
        onAnswer?(question.isGoodAnswer(result: result))
    }
    private func nextQuestion() -> Question? {
        currentQuestion = questions.next()
        return currentQuestion
    }
}

/** View */
struct QuestionView {
    func show(question: Question) {
        print(question.question)
    }
}

struct PromptView {
    func show() {
        print("> ", terminator: "")
    }
}

class MainView {
    private let questionView = QuestionView()
    private let promptView = PromptView()
    
    /** Initialization will requre the pass ViewModel (The viewModel is often attached to the following:) */
    let viewModel: ViewModel
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        bindViewModel()
    }
    
    func bindViewModel() {
        viewModel.onQuestionChanged = { [unowned self] in
            guard
                let string = self.viewModel.getQuestionText() else {
                // No more questions?
                self.finishPlaying()
                return
            }
            self.ask(question: string)
        }
        viewModel.onAnswer = { [unowned self] (isGood) -> Void in
            if isGood {
                self.goodAnswer()
            } else {
                self.badAnswer()
            }
        }
    }
    private func ask(question: Question) {
        questionView.show(question: question)
        promptView.show()
    }
    func goodAnswer() {}
    func badAnswer() {}
    func finishPlaying() {}
}

// Create a new ViewModel instance
let viewModel = ViewModel()
// Inject the viewModel into the view
let view = MainView(viewModel: viewModel)
// Start the viewModel
viewModel.start()

// MARK: - MVC Pattern

/** The model layer */
// Question.swift
enum BooleanAnswer: String {
    case `true`
    case `false`
}

struct Question {
    let question: String
    let answer: BooleanAnswer
}

extension Question {
    func isGoodAnswer(result: String?) -> Bool {
        return result == answer.rawValue
    }
}

// QuestionController.swift
class QuestionController {
    private var questions = [Question]()
    
    func load() { /* Load from disk, memory or else */ }
    func next() -> Question? {
        return questions.popLast()
    }
}

/** The view layer
 Display information, not gather input
 */
struct QuestionView {
    func show(question: Question) {
        print(question.question)
    }
}

struct PromptView {
    func show() {
        print(">", terminator: "")
    }
}

class ViewController {
    private let questionView = QuestionView()
    private let promptView = PromptView()
    
    func ask(question: Question) {
        questionView.show(question: question)
        promptView.show()
    }
    func goodAnswer() { print("Good!") }
    func badAnswer() { print("Bad!") }
    func finishPlaying() { print("Done!") }
}

/** The controller layer */
class GameController {
    private let questions = QuestionController()
    private let view = ViewController()
    
    private func waitForAnswer(question: Question) {
        // Wait for user input
        let result = readLine()
        // Ask the model if answer is good
        if question.isGoodAnswer(result: result) {
            // Update view
            view.goodAnswer()
        } else {
            view.badAnswer()
        }
    }
    
    func start() {
        // From the model layer, get the next question
        while let question = questions.next() {
            // Display the question on screen
            view.ask(question: question)
            waitForAnswer(question: question)
        }
        view.finishPlaying()
    }
}

// main.swift
GameController().start()

// MARK: - Swift-Oriented Pattern - Template with protocol-oriented programming
/**
 -Usually implemented with abstract class
 -Design algorithms at high level while letting subclasses or implementers modify or provide parts of it
 -Default implementations are suited for generic algorithms that can lter be applied to a slew of concrete types
 -Useful when only parts of an algorithm is dynamic and those changes can or should be deffered to sublcasses and have no effect on the overall algorithm
 */

protocol RecommendationEngine {
    associatedtype Model
    var models: [Model] { get }
    func filter(elements: [Model]) -> [Model]
    func sort(elements: [Model]) -> [Model]
}

extension RecommendationEngine {
    func match() -> Model? {
        // If there is only 0 or 1 models, no need to run the algorithm
        guard
            models.count > 1 else { return models.first }
        return sort(elements: filter(elements: models)).first
    }
}

struct Restaurant {
    var name: String
    var visited: Bool
    var score: Double
}

let restaurants = [
    Restaurant(name: "Tony's Pizza", visited: true, score: 2.0),
    Restaurant(name: "Krusty's", visited: true, score: 3.0),
    Restaurant(name: "Bob's Burger", visited: false, score: 4.9)
]

struct FavoriteEngine: RecommendationEngine {
    var models: [Restaurant]
    // Filter only the restaurants visited
    func filter(elements: [Restaurant]) -> [Restaurant] {
        return elements.filter { $0.visited }
    }
    /** Conditional Conformance
    func sort(elements: [Restaurant]) -> [Restaurant] {
        return elements.sorted { $0.score > $1.score }
    }
     */
}

let favoriteEngine = FavoriteEngine(models: restaurants)
let favoriteMatch = favoriteEngine.match()
print(favoriteMatch!)

struct BestEngine: RecommendationEngine {
    var models: [Restaurant]
    func filter(elements: [Restaurant]) -> [Restaurant] {
        return elements.filter { !$0.visited } // ! Bool = false
    }
    /** Conditional Conformance
    func sort(elements: [Restaurant]) -> [Restaurant] {
        return elements.sorted { $0.score > $1.score }
    }
     */
}

let bestEngine = BestEngine(models: restaurants)
let bestMatch = bestEngine.match()
print(bestMatch!)

extension RecommendationEngine where Model == Restaurant {
    /** Conditional Conformance (reason: sorting algorithm duplication) */
    func sort(elements: [Model]) -> [Model] {
        return elements.sorted { $0.score > $1.score }
    }
}

// MARK: - Swift-Oriented Pattern - Type Erasure*
/**
 Remove type annotations from a particular program
 Represent protocols with associated types into a concrete type with generics
 */

protocol Food {}
protocol Animal {
    /**
     -Associated type can be thought about a generic type added on protocol
     -FoodType is a placeholder that will be determined by the class or structure iimplementing the protocol
     -Conveyed that FoodType should conform to the Food protocol
     */
    associatedtype FoodType: Food
    func eat(food: FoodType)
}

struct Grass: Food {}

struct Cow: Animal {
    func eat(food: Grass) {
        print("Grass is yummy! moooooo!")
    }
}

struct Goat: Animal {
    func eat(food: Grass) {
        print("Grass is good! meehhhh!")
    }
}

// Elements of type erasure
class AnyAnimal<T>: Animal where T: Food {
    /** Wrapper
     Basic erasure type suited that has few methods
     */
    typealias FoodType = T
    func eat(food: T) {}
}

// Closure-based type Erasure
final class AnyAnimalV2<T>: Animal where T: Food {
    /** Wrapper
     This type will be used as proxy to the Animal type
     Changes from basic:
     -Mark final to avoid wrong usage
     -Added an 'eatBlock: (T) -> Void' property to CAPTURE the eat method
     -Added 'func eat(food: T)' to FORWARD the calls to original method
     -Added generic initializer that also binds the T type to FoodType of the provided Animal type, A.FoodType
     */
    typealias FoodType = T
    private let eatBlock: (T) -> Void
    
    init<A: Animal>(animal: A) where A.FoodType == T {
        eatBlock = animal.eat
    }
    
    func eat(food: T) {
        eatBlock(food)
    }
}

let aCow = AnyAnimalV2(animal: Cow())
let aGoat = AnyAnimalV2(animal: Goat())
let grassEaters = [aCow, aGoat]
assert(grassEaters is [AnyAnimalV2<Grass>])

grassEaters.forEach { (animal) in
    animal.eat(food: Grass())
}

// Boxing-based type erasure
/**
 -An abstract base class
 -A private box, which will inherit the abstract base class
 -A public wrapper
 */
protocol AnimalV2 {
    associatedtype FoodType: Food
    var preferredFood: FoodType? { get set }
    var name: String { get }
    func eat(food: FoodType)
}

final class AnyAnimalV3<T>: Animal where T: Food {
    typealias FoodType = T
    var prefferedFood: T?
    let name: String = ""
    func eat(food: T) {}
}

/** Abstract base class
 -Conforms to our base protocol
 -An abstract class so provides a top implementation for the private box
 -Defines a generic prameter, T or F, bound to the associated type
 */

private class _AnyAnimalBase<F>: AnimalV2 where F: Food {
    /** Abstract Class Convention: _Any#MY_PROTOCOL#BASE<> */
    var preferredFood: FoodType? {
        get { fatalError() }
        set { fatalError() }
    }
    var name: String { fatalError() }
    func eat(food: F) { fatalError() }
}

/** Private box  */
private final class _AnyAnimalBox<A: AnimalV2>: _AnyAnimalBase<A.FoodType> {
    /**
     -Implements the abstract base class.
     -Provide a wrapper around the concrete object impleneting the PAT and forward all calls to boxed object
     */
    // The target object, that is an Animal
    var target: A
    init(_ target: A) {
        self.target = target
    }
    
    // Overrides the abstract classes' implementation
    // Forward all invocations to the concrete target
    override var name: String {
        return target.name
    }
    override var preferredFood: A.FoodType? {
        get { return target.preferredFood }
        set { target.preferredFood = newValue }
    }
    override func eat(food: A.FoodType) {
        target.eat(food: food)
    }
    
    /**
     As AnyAnimalBox class extends AnyAnimalBase, it will be able to keep references of our boxes as their abstract class type,
     which successfully bridges the world of protocols and their associated types to the world of generics
     */
}

// Public wrapper
final class AnyAnimalV31<T>: AnimalV2 where T: Food {
    typealias FoodType = T
    private let box: _AnyAnimalBase<T>
    
    init<A: AnimalV2>(_ animal: A) where A.FoodType == T {
        box = _AnyAnimalBox(animal)
    }
    
    // Call forwarding for implementing Animal
    var preferredFood: T? {
        get { return box.preferredFood }
        set { box.preferredFood = newValue }
    }
    var name: String {
        return box.name
    }
    func eat(food: T) {
        box.eat(food: food)
    }
}

struct CowV2: AnimalV2 {
    var name: String
    var preferredFood: GrassV2? = nil
}

struct GoatV2: AnimalV2 {
    var name: String
    var preferredFood: GrassV2? = nil
}

extension AnimalV2 where FoodType: GrassV2 {
    func eat(food: FoodType) {
        if let preferredFood = preferredFood,
           type(of: food) == type(of: preferredFood) {
            print("\(name): Yummy! \(type(of: food))")
        } else {
            print("\(name): I'm eating...")
        }
    }
}

class GrassV2: Food {}
class Flower: GrassV2 {}
class Dandelion: GrassV2 {}
class Shamrock: GrassV2 {}

let flock = [
    AnyAnimalV31(CowV2(name: "Bessie", preferredFood: Dandelion())),
    AnyAnimalV31(CowV2(name: "Henrietta")),
    AnyAnimalV31(GoatV2(name: "Billy", preferredFood: Shamrock())),
    AnyAnimalV31(GoatV2(name: "Nanny", preferredFood: Flower()))
]

let flowers = [
    GrassV2(),
    Dandelion(),
    Flower(),
    Shamrock()
]

while true {
    flock.randomElement()?
        .eat(food: flowers.randomElement()!)
    sleep(1)
}

// MARK: - Swift-Oriented Pattern - Getting Started


// Protocols
 /**
  Protocols cannot be used as types when they are associated with another type,
  in the form of Self or associated type requirement
  */
 
/** Adding requirements to protocols */
protocol DemoProtocol {
    var aRequiredProperty: String { get set }
    var aReadOnlyProperty: Double { get }
    static var aStaticProperty: Int { get }
    
    init(requiredProperty: String)
    
    func doSomething() -> Bool
}

/**
 Can (and should) use protocols as types:
 -Return type (parameter of a function)
 -Member (variable or constant)
 -Within arrays, dictionaries, or other container types
 */
protocol RunnerDelegate: AnyObject {
    func didStart(runner: Runner)
    func didStop(runner: Runner)
}

class Runner {
    weak var delegate: RunnerDelegate?
    func start() {
        delegate?.didStop(runner: self)
    }
    func stop() {
        delegate?.didStop(runner: self)
    }
}


// Generics-based programming
/** Write flexible code that works with any type and that follows the requirements settles at COMPILE TIME */

func compare<T>(_ a: T, _ b: T) -> Int where T: Comparable {
    /**
     - '<T>' indicates that this function is generic
     - 'a: T, b: T' indicates that this method takes two parameters of the T type
     - 'where T: Comparable' indicates that T is required to conform to the Comparable protocol
     */
    if a > b { return 1 }
    if a < b { return -1 }
    return 0
}

// Conditional conformance
/** Provide conformance or extensions to existing types on the condition that set of a requirements is fufilled */
protocol Summable {
//    var sum: Int { get }
    
    // Uncomment for Numeric conformance
    associatedtype SumType
    var sum: SumType { get }
}

/** Retrofit this type on Arrays of Int types to add integers together to produce a sum */
//extension Array: Summable where Element == Int {
//    var sum: Int {
//        return self.reduce(0) { $0 + $1 }
//    }
//}

//assert([1, 2, 3, 4].sum == 10)

// Uncomment for Numeric conformance
extension Array: Summable where Element: Numeric {
    /**
     Breakdown:
     - "extension Array: Summable" declares that Array is extending to be Summable
     - "where Element: Numeric" is only for arrays that habve their elements of the numeric type
     - "typealias SumType = Element" declares that the sum will be the type of the array Element typ, not Numeric
     */
    typealias SumType = Element
    var sum: Element {
        return self.reduce(0) { $0 + $1 }
    }
}

let intSum = [1,2,3,4,5].sum
let doubleSum = [1.0,2.0,3.0,4.0].sum
let floatSum: Float = [1.0,2.0,3.0,4.0].sum
assert(intSum is Int)
assert(doubleSum is Double)
assert(floatSum is Float)

extension Array/* : Summable */where Element == String {
    /** Cannot declare multiple confomances with different restrictions */
    var sum: String {
        return self.reduce("") { $0 + $1 }
    }
}

assert(["Hello", " ", "World", "!"].sum == "Hello World!")

// Associated types

protocol Food {}

/**
 // Error: Type 'Cow' does not conform to protocol 'Animal'
 
 protocol Animal {
     func eat(food: Food)
 }
 
struct Cow: Animal {
    func eat(food: Grass) {}
}
 */

// Refactor Animal
protocol Animal {
    /**
     -Associated type can be thought about a generic type added on protocol
     -FoodType is a placeholder that will be determined by the class or structure iimplementing the protocol
     -Conveyed that FoodType should conform to the Food protocol
     */
    associatedtype FoodType: Food
    func eat(food: FoodType)
}

struct Grass: Food {}
struct Meat: Food {}
struct Cow: Animal {
    func eat(food: Grass) {}
}
struct Lion: Animal {
    func eat(food: Meat) {}
}

// Feed all animal
/** Self requirement errors
 Error: Use of protocol 'Animal as a type must be written 'any Animal'
 Alt Error: Protocol 'Animal' can only be used as generic constraint because it has self or associated type req
 
 func feed(animal: Animal) {}
 
 Solve by using Animal as a generic constraint
 */

// Generic constraint
func feed<A: Animal>(animal: A) {
    switch animal {
        case let cow as Cow:
            cow.eat(food: Grass())
            print("The \(animal) is eating grass")
        case let lion as Lion:
            lion.eat(food: Meat())
            print("The \(animal) is eating meat")
        default:
            print("I can't feed...")
            break
    }
}

feed(animal: Cow())
feed(animal: Lion())

// Consider all animals in a single array
/** Self requirement errors
 Error: Use of protocol 'Animal as a type must be written 'any Animal'
 Alt Error: Protocol 'Animal' can only be used as generic constraint because it has self or associated type req
 
 var animal = [Animal]()
 
 Cannot store animals altogether
 Experiment with a generic class
 */

// Generic class
class AnimalHolder<T> where T: Animal {
    var animals = [T]()
}
print("\n")
let holder = AnimalHolder<Cow>()
let cow = Cow()
print(holder.animals)
holder.animals.append(cow)
print(holder.animals)

// Self requirement
/** Consider: */
protocol Thing {
    associatedtype AType
}

struct Node: Thing {
    /** Node confroms to Thing and sets its AType associatedtype to itself via typealias */
    typealias AType = Thing // Self associated type
}
/** Self requirement error
let thing: Thing = Node()
 */

// MARK: - Behavioral Pattern - Strategy
/**
 Write programs that are able to select different algorithms or strategies at runtime
 -Complex classes with multiple algorithms changing at runtime
 -Algorithms that may improve performance and need to be swapped at runtime
 -Multiple implementations of similar algorithms in different classes, making them difficult to extract
 -Complex algorithms that are stronglhy tied to data structures
 Isolate those algorithms from the context they operate in
 Components:
 -Context objects, which will have a Strategy member
 -Stragey implemtations that can be swapped at runtime
 */

protocol Strategy {
    /** The algorithm that runs the code, and that will be swapped at runtime */
    associatedtype ReturnType
    associatedtype ArgumentType
    func run(argument: ArgumentType) -> ReturnType
}

protocol Context {
    associatedtype StrategyType: Strategy
    var strategy: StrategyType { get set }
}

// The ice-cream shop example

enum IceCreamPart {
    case waffer
    case cup
    case scoop(Int)
    case chocolateDip
    case candyTopping
    
    var price: Double {
        switch self {
            case .scoop:
                return 2.0
            default:
                return 0.25
        }
    }
}

extension IceCreamPart: CustomStringConvertible {
    var description: String {
        switch self {
            case .scoop(let count):
                return "\(count)x scoops"
            case .waffer:
                return "1x waffer"
            case .cup:
                return "1x cup"
            case .chocolateDip:
                return "1x chocolate dipping"
            case .candyTopping:
                return "1x candy topping"
        }
    }
}

protocol BillingStrategy {
    func add(item: IceCreamPart) -> Double
}

class FullPriceStrategy: BillingStrategy {
    func add(item: IceCreamPart) -> Double {
        switch item {
            case .scoop(let count):
                return Double(count) * item.price
            default:
                return item.price
        }
    }
}

class HalfPriceToppings: FullPriceStrategy {
    override func add(item: IceCreamPart) -> Double {
        if case .candyTopping = item {
            return item.price / 2.0
        }
        return super.add(item: item)
    }
}

struct Bill {
    var strategy: BillingStrategy
    var items = [(IceCreamPart, Double)]()
    
    init(strategy: BillingStrategy) {
        self.strategy = strategy
    }
    
    mutating func add(item: IceCreamPart) {
        let price = strategy.add(item: item)
        items.append((item, price))
    }
    
    func total() -> Double {
        return items.reduce(0) { (total, item) -> Double in
            return total + item.1
        }
    }
}

extension Bill: CustomStringConvertible {
    var description: String {
        return items.map { (item) -> String in
            return item.0.description + " $\(item.1)"
        }.joined(separator: "\n")
        + "\n-------"
        + "\nTotal $\(total())\n"
    }
}

var bill = Bill(strategy: FullPriceStrategy())
bill.add(item: .waffer)
bill.add(item: .scoop(1))
bill.add(item: .candyTopping)
print(bill.description) //typeOf: String

bill = Bill(strategy: FullPriceStrategy())
bill.add(item: .cup)
bill.add(item: .scoop(3))
bill.strategy = HalfPriceToppings()
bill.add(item: .candyTopping)
print(bill) //typeOf: Bill

// Introduced a loyalty program
class HalfPriceStrategy: FullPriceStrategy {
    override func add(item: IceCreamPart) -> Double {
        return super.add(item: item)  / 2.0
    }
}

bill = Bill(strategy: HalfPriceStrategy())
bill.add(item: .waffer)
bill.add(item: .scoop(1))
bill.add(item: .candyTopping)
print(bill) //typOf: Bill

// MARK: - Behavioral Pattern - Visitor
/**
 Building a complex algorithms that are independent from the data they consume
 Ability to implement multiple distinct operations, without changing the underlying object structure
 Series of protocols that each object has to implement:
 -Define Visitable, elements that can be visited
 -Define Visitor, helps traverse Visitable objects
 -Extend existing objects to be Visitable
 -Implement on or many Visitor Object and their logic
 */

protocol Visitor {
    func visit<T>(element: T) where T: Visitable
}

protocol Visitable {
    func accept(visitor: Visitor)
}

extension Visitable {
    /** Default Implementation for visitable nodes--generics are not needed */
    func accept(visitor: Visitor) {
        visitor.visit(element: self)
    }
}

extension Array: Visitable where Element: Visitable {
    func accept(visitor: Visitor) {
        visitor.visit(element: self)
        forEach {
            visitor.visit(element: $0)
        }
    }
}

struct Contribution {
    let date: Date
    let author: String
    let email: String
    let details: String
}

extension Contribution: Visitable {
    /** As Contribution is Visitable , [Contribution] will also be so, thanks to the protocol extension Array */
}

class LoggerVisitor: Visitor {
    func visit<T>(element: T) where T : Visitable {
        guard
            let contribution = element as? Contribution else { return }
        print("\(contribution.author) / \(contribution.email)")
    }
}

let visitor = LoggerVisitor()

[
    Contribution(date: Date(),
                 author: "Contributor",
                 email: "my@email.com",
                 details: "")
].accept(visitor: visitor)

[
    Contribution(date: Date(),
                 author: "Contributor 2",
                 email: "my-other@email.com",
                 details: "")
].accept(visitor: visitor)

let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!

class ThankYouVisitor: Visitor {
    var contributions = [Contribution]()
    func visit<T>(element: T) where T : Visitable {
        guard
            let contribution = element as? Contribution else { return }
        // Check that the contribution was done between 3 and 4 days ago
        if contribution.date <= threeDaysAgo && contribution.date > fourDaysAgo {
            contributions.append(contribution)
        }
    }
}

let thanksVisitor = ThankYouVisitor()
Contribution(date: threeDaysAgo,
             author: "John Duff",
             email: "john@email.com",
             details: "...")
.accept(visitor: thanksVisitor)

let allContribution = [Contribution]()
allContribution.accept(visitor: thanksVisitor)

/** Send thanks!
 thanksVisitor.contributions.forEach {
     sendThanks($0)
} */

// MARK: - Behavioral Pattern - Memento
/**
 Preserve multiple states of program or models
 
 Memento: a representation of the internal state of Originator, which should be immutable
 Originator: the original object that can produce and consume the Memento, in order to save and restore its own state
 CareTaker: an external object that stores and restores a Memento to an Originator
 */

protocol Originator {
    /**
     Two responsibilities:
     -CREATE mementos for CareTaker
     -RESTORE its state using the setMemento()
     */
    
    associatedtype MementoType
    func createMemento() -> MementoType
    mutating func setMemento(_ memento: MementoType)
}

protocol CareTaker {
    associatedtype OriginatorType: Originator
    var originator: OriginatorType { get set } // able to get and restore Memento obj from it
    var mementos: [OriginatorType.MementoType] { get set }
    mutating func save()
    mutating func restore()
}

extension CareTaker {
    mutating func save() {
        mementos.append(originator.createMemento())
    }
    
    mutating func restore() {
        guard
            let memento = mementos.popLast() else { return }
        originator.setMemento(memento)
    }
}

struct Item {
    /** want all features of value types such as immutability and copy-on-write */
    var name: String
    var done: Bool = false
}

extension Array: Originator {
    /** all array types are Originator objects, and the MementoType is [Element] */
    func createMemento() -> [Element] {
        return self
    }
    mutating func setMemento(_ memento: [Element]) {
        self = memento
    }
}

class ShoppingList: CareTaker {
    var list = [Item]()
    
    /** Memento will store the different states of the list when calling save() or restore(); the Originator is the list of items itself */
    var mementos: [[Item]] = []
    var originator: [Item] {
        get { return list }
        set { list = newValue }
    }
    
    // convenient method
    func add(_ name: String) {
        list.append(Item(name: name, done: false))
    }
    func toggle(itemAt index: Int) {
        list[index].done.toggle()
    }
}

extension String {
    var strikeThrough: String {
        return self.reduce("") { (partialResult, char) -> String in
            return partialResult + "\(char)" + "\u{0336}"
        }
    }
}

extension Item: CustomDebugStringConvertible {
    var debugDescription: String {
        return done ? name.strikeThrough : name
    }
}

extension ShoppingList: CustomDebugStringConvertible {
    var debugDescription: String {
        return list.map { $0.debugDescription }.joined(separator: "\n")
    }
}

var shoppingList = ShoppingList()
shoppingList.add("Fish")
shoppingList.save()

shoppingList.add("Karrots") // wrong spelling
shoppingList.restore()
print("1--\n\(shoppingList)\n\n")

shoppingList.add("Carrots") // correct spelling
print("2--\n\(shoppingList)\n\n")
shoppingList.save()

shoppingList.toggle(itemAt: 1) // mark as picked up
print("3--\n\(shoppingList)\n\n")

shoppingList.restore() // picked up wrong item
print("4--\n\(shoppingList)\n\n")

// MARK: - Behavioral Pattern - Observer - Observation using pure Swift

struct Article {
    var title: String = "" {
        willSet {
            // the title is the value before setting
            if title != newValue {
                print("The title will change to \(newValue)")
            }
        }
        didSet {
            // the title is the value after it's been set
            if title != oldValue {
                print("The title has changed from \(oldValue)")
            }
        }
    }
}

var article = Article()
article.title = "A Good Title"
article.title = "A Good Title"
article.title = "A Better Title"

// MARK: - Structural Pattern - Flyweight
/**
 USAGE:
 -Creating many instances of the same object
 -Afford to use memory to cache instances
 -Does not mutate those instances, and can afford to share across the program
 */

struct Ingredient: CustomDebugStringConvertible {
    let name: String
    var debugDescription: String{
        return name
    }
}

struct IngredientManager {
    private var knownIngredients = [String: Ingredient]()
    mutating func get(withName name: String) -> Ingredient {
        // Check if instance exist
        guard
            let ingredient = knownIngredients[name] else {
            // Register an instance
            knownIngredients[name] = Ingredient(name: name)
            // Attempt to get again
            return get(withName: name)
        }
        return ingredient
    }
    var count: Int { return knownIngredients.count }
}

struct ShoppingList: CustomDebugStringConvertible {
    private var list = [(Ingredient, Int)]()
    private var manager = IngredientManager()
    mutating func add(item: String, amount: Int = 1) {
        let ingredient = manager.get(withName: item)
        list.append((ingredient, amount))
    }
    var debugDescription: String {
        return "\(manager.count)  Items: \n\n"
        + list.map({ (ingredient, value) in
            return "\(ingredient) (x\(value))"
        }).joined(separator: "\n")
    }
}

let items = ["kale", "carrots", "salad", "carrots", "cucumber", "celery", "pepper", "bell peppers", "carrots", "salad"]
items.count

var shopping = ShoppingList()
items.forEach {
    shopping.add(item: $0)
}
print(shopping)

// MARK: - Structural Pattern - Bridge Pattern*
/**
 Architecture and testability.
 Swap at runtime which object performs the work:
 -Abstraction
 -Implementor
 */

protocol ImplementorType {
    func start()
    func stop()
}

protocol AbstractionType {
    // needs to be initialized with implementor
    init(implementor: ImplementorType)
    func start()
    func stop()
}

extension AbstractionType {
    func restart() {
        stop()
        start()
    }
}

class Abstraction: AbstractionType {
    private let implementor: ImplementorType
    
    required init(implementor: ImplementorType) {
        self.implementor = implementor
    }
    func start() {
        print("starting")
        implementor.start()
    }
    func stop() {
        print("Stopping")
        implementor.stop()
    }
}

class Implementor1: ImplementorType {
    func start() {
        print("Implementor1.start()")
    }
    func stop() {
        print("Implementor1.stop()")
    }
}

class Implementor2: ImplementorType {
    func start() {
        print("Implementor2.start()")
    }
    func stop() {
        print("Implementor2.stop()")
    }
}

var abstraction = Abstraction(implementor: Implementor1())
abstraction.restart()
abstraction = Abstraction(implementor: Implementor2())
abstraction.restart()

class TestImplementor: ImplementorType {
    var stopCalled = false
    var startCalled = false
    var inProperOrder = false
    
    func start() {
        inProperOrder = stopCalled == true && startCalled == false
        startCalled = true
        print("Testimplementor.start() \(startCalled) \(stopCalled) \(inProperOrder)")
    }
    func stop() {
        inProperOrder = startCalled == false && stopCalled == false
        stopCalled = true
        print("TestImplementor.stop() \(startCalled) \(stopCalled) \(inProperOrder)")
    }
}

print("")
let testImplementor = TestImplementor()
abstraction = Abstraction(implementor: testImplementor)
abstraction.restart()

assert(testImplementor.inProperOrder)
assert(testImplementor.startCalled)
assert(testImplementor.stopCalled)

// MARK: - Structural Pattern - Facade Pattern*
/**
 Reduce the apparent complexity of a subsystem, by exposing a simpler interface.
 Hide multiple tightly coupled subcomponents behind a single object or method.
 -URLSession: A system that fetches a resource based on its URLRequest
 -Cache: The subsystem responsible for storing the results of the resource fetcher
 -CacheCleaner: The subsystem responsible for periodically running over the cache and actively removing stale data
 */

class Cache {
    func set(response: URLResponse, data: Data, for request: URLRequest) {}
    func get(for request: URLRequest) -> (URLResponse, Data)? {}
    func remove(for request: URLRequest) {}
    func allData() -> [URLRequest: (URLResponse, Data)] {
        return [:]
    }
}

class CacheCleaner {
    let cache: Cache
    var isRunning: Bool {
        return timer != nil
    }
    
    private var timer: Timer?
    init(cache: Cache) {
        self.cache = cache
    }
    
    func startIfNeeded() {
        if isRunning { return }
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [unowned self] (timer) in
            let cacheData = self.cache.allData()
        })
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

class CachedNetworking {
    let session: URLSession
    private let cache = Cache()
    private lazy var cleaner = CacheCleaner(cache: cache)
    
    init(configuration: URLSessionConfiguration) {
        session = URLSession(configuration: configuration)
    }
    
    init() {
        self.session = URLSession.shared
    }
    
    func run(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?, Bool) -> Void) {
        if let (response, data) = cache.get(for: request) {
            completionHandler(data, response, nil, true)
            return
        }
        cleaner.startIfNeeded()
        session.dataTask(with: request) { [weak self] (data, response, error) in
            if let data = data,
               let reponse = response {
                self?.cache.set(response: reponse, data: data, for: request)
            }
            completionHandler(data, response, error, false)
        }.resume()
    }
    deinit {
        cleaner.stop()
    }
}

// MARK: - Structural Pattern - Decorator Pattern
/**
 Allows to add behaviors to objects without changing their structure or inheritance chain.
 Instead of subclassing, decorators enhance an object's behavior by adding functionalities
 */

public protocol Burger {
    var price: Double { get }
    var ingredients: [String] { get }
}

public protocol BurgerDecorator: Burger {
    var burger: Burger { get }
}

extension BurgerDecorator {
    public var price: Double {
        return burger.price
    }
    public var ingredients: [String] {
        return burger.ingredients
    }
}

public struct BaseBurger: Burger {
    public var price = 1.0
    public var ingredients = ["buns"]
}

public struct WithCheese: BurgerDecorator {
    public let burger: Burger
    public var price: Double { return burger.price + 0.5 }
    
    public var ingredients: [String] {
        return burger.ingredients + ["cheese"]
    }
}

public struct WithIncredibleBurgerPatty: BurgerDecorator {
    public let burger: Burger
    public var price: Double { return burger.price + 2.0 }
    
    public var ingredients: [String] {
        return burger.ingredients + ["incredible patty"]
    }
}

enum Topping: String {
    case ketchup
    case mayonnaise
    case salad
    case tomato
}

struct WithTopping: BurgerDecorator {
    let burger: Burger
    let topping: Topping
    var ingredients: [String] {
        return burger.ingredients + [topping.rawValue]
    }
}

var burger: Burger = BaseBurger()
burger = WithTopping(burger: burger, topping: .ketchup)
burger = WithCheese(burger: burger)
burger = WithIncredibleBurgerPatty(burger: burger)
burger = WithTopping(burger: burger, topping: .salad)

print(burger.ingredients)
print(burger.price)
assert(burger.ingredients == ["buns", "ketchup", "cheese", "incredible patty", "salad"])
assert(burger.price == 3.5)

extension Topping {
    func decorate(burger: Burger) -> WithTopping {
        return WithTopping(burger: burger, topping: self)
    }
}

var decorators = [(Burger) -> Burger]() // constructor or method?
decorators.append(Topping.ketchup.decorate(burger:))
decorators.append(WithCheese.init)
decorators.append(WithIncredibleBurgerPatty.init)
decorators.append(Topping.salad.decorate)
print(decorators)
let reducedBurger = decorators.reduce(into: BaseBurger()) { partialResult, decorate in
    partialResult = decorate(partialResult)
}
print(reducedBurger.price)
print(reducedBurger.ingredients)
assert(burger.ingredients == reducedBurger.ingredients)
assert(burger.price == reducedBurger.price)
 
// MARK: - Creational Pattern - Builder Pattern
/**
 An abstract way the construction of objects or values that require a large number of parameters by using an intermediate representation.
 */

struct Article {
    let id: String
    let title: String
    let contents: String
    let author: String
    let date: Date
    var views: Int
}

extension Article {
    /** Does not pollute the original struct with the builder code */
    
    class Builder {
        private var id: String = "123"
        private var title: String?
        private var contents: String?
        private var author: String?
        private var date: Date = Date()
        private var views: Int = 0
        
        func set(id: String) -> Builder {
            self.id = id
            return self
        }
        func set(title: String) -> Builder {
            self.title = title
            return self
        }
        func set(content: String) -> Builder {
            self.contents = content
            return self
        }
        func set(author: String) -> Builder {
            self.author = author
            return self
        }
        func set(date: Date) -> Builder {
            self.date = date
            return self
        }
        func set(views: Int) -> Builder {
            self.views = views
            return self
        }
        func build() -> Article {
            /** !! IMPORTANT !! Returns the new instance of the original type */
            return Article(id: id,
                           title: title!,
                           contents: contents!,
                           author: author!,
                           date: date,
                           views: views)
        }
    }
}

let builder = Article.Builder()

// MARK: - Refreshing The Basics

func get<T>(url: URL, callback: @escaping (T?, Error?) -> Void) -> URLSessionTask where T: Decodable {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            callback(nil, error)
            return
        }
        if let data = data {
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                callback(result, nil)
            } catch {
                callback(nil, error)
            }
        } else {
            callback(nil, nil)
        }
    }
    task.resume()
    return task
}

protocol Toggling {
    mutating func toggle()
    var isActive: Bool { get }
}

enum State: Int, Toggling {
    case off = 0
    case on
    mutating func toggle() {
        self = self == .on ? .off : .on
    }
}

extension Bool: Toggling {
    mutating func toggle() {
        self = !self
    }
}

var isReady = false
isReady.toggle()


extension Toggling where Self == Bool {
    var isActive: Bool {
        return self
    }
}

extension Toggling where Self == State {
    var isActive: Bool {
        return self == .on
    }
}

enum State<T>: Equatable where T: Equatable {
    case on
    case off
    case dimmed(T)
}

struct Bit8Dimming: Equatable {
    let value: Int
    init(_ value: Int) {
        assert(value > 0 && value < 256)
        self.value = value
    }
}

struct ZeroOneDimming: Equatable {
    let value: Double
    init(_ value: Double) {
        assert(value > 0 && value < 1)
        self.value = value
    }
}

var nostalgiaState: State<Bit8Dimming> = .dimmed(.init(10))
let otherState: State<ZeroOneDimming> = .dimmed(.init(0.4))

extension State {
    mutating func toggle() {
        self = self == .off ? .on: .off
    }
}

nostalgiaState = .on
nostalgiaState.toggle()

//var state: State = .on
//state.toggle()
//print(state)
//state.toggle()
//print(state)

class Point {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

struct Point {
    var x: Double
    var y: Double
}

func translate(point: inout Point, dx: Double, dy: Double) {
    point.x += dx
    point.y += dy
}

func translate(point: Point, dx: Double, dy: Double) -> Point {
    var point = point
    translate(point: &point, dx: dx, dy: dy)
    return point
}

var point = Point(x: 0.0, y: 0.0)
translate(point: &point, dx: 1.0, dy: 1.0)
let translatedPoint = translate(point: point, dx: 1.0, dy: 1.0)
point.x == 0.0
point.y == 0.0
translatedPoint.x == 1.0
translatedPoint.y == 1.0

extension Point {
    func translating(dx: Double, dy: Double) -> Point {
        return translate(point: self, dx: dx, dy: dy)
    }
}

let point2 = Point(x: 0.0, y: 0.0)
    .translating(dx: 5.0, dy: 2.0)
    .translating(dx: 2.0, dy: 3.0)
point2.x == 7.0
point2.y == 5.0

func returnAny(randomType: Any) -> Any {
     return randomType
 }

 returnAny(randomType: "Hello World")
 print(type(of: returnAny(randomType: "Hello World")))
 returnAny(randomType: 123)
 print(type(of: returnAny(randomType: 123)))

 let arr = ["A", "B", "C", "D", "F", "U"]

enum MessageBoard {
    case text(userID: String, contents: String, date: Date)
}

var logMsg = [MessageBoard]()
let msg = MessageBoard.text(userID: "USER0", contents: "content0", date: Date())
let msg1 = MessageBoard.text(userID: "USER1", contents: "content1", date: Date())
let msg2 = MessageBoard.text(userID: "USER2", contents: "content2", date: Date())
logMsg.append(msg)
logMsg.append(msg1)
logMsg.append(msg2)

for msg in logMsg {
    print(msg)
}

print()

// Closure

struct Company: CustomStringConvertible {
    let name: String
    var description: String {
        return "Company name is \(name)"
    }
}

let debug = true

func debugLog(message: () -> String) {
    if debug {
        print("debug: \(message())")
    }
}

let apple = Company(name: "Apple")
debugLog { apple.description }

// Protocol

protocol Worker {
    associatedtype Input
    associatedtype Output
    
    @discardableResult // ???
    func start(input: Input) -> Output
}

func runWorker<W: Worker>(worker: W, input: [W.Input]) {
    input.forEach { (value: W.Input) in
        worker.start(input: value)
    }
}

final class User {
    let fName: String
    let lName: String
    init(fName: String, lName: String) {
        self.fName = fName
        self.lName = lName
    }
}

class MailJob: Worker {
    typealias Input = String
    typealias Output = Bool
    
    func start(input: String) -> Bool {
        return true
    }
}

let mailJob = MailJob()

let user = User(fName: "orlan", lName: "tompkins")
func runWorker<W>(worker: W, input: [W.Input])
where W: Worker, W.Input == User {
    input.forEach { (user: W.Input) in
        worker.start(input: user)
        print("Finished processing user \(user.fName) \(user.lName)")
    }
}

runWorker(worker: mailJob.start(input: "@email"), input: [user.fName, user.lName])

