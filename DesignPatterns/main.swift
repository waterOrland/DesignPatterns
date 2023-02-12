//
//  main.swift
//  DesignPatterns
//
//  Created by Orland Tompkins on 2/01/23.
//

import Foundation

// MARK: - Memento Pattern
/**
 Preserve multiple states of program or models
 
 Memento: a representation of the internal state of Originator, which should be immutable
 Originator: the original object that can produce and consume the Memento, in order to save and restore its own state
 CareTaker: an external object that stores and restores a Memento to an Originator
 */

/*
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

*/

// MARK: - Observer Pattern - Observation using pure Swift
/*
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
*/

// MARK: - Flyweight Pattern
/**
 USAGE:
 -Creating many instances of the same object
 -Afford to use memory to cache instances
 -Does not mutate those instances, and can afford to share across the program
 */

/*
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
*/

// MARK: - Bridge Pattern*
/**
 Architecture and testability.
 Swap at runtime which object performs the work:
 -Abstraction
 -Implementor
 */

/*
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
*/

// MARK: - Facade Pattern*
/**
 Reduce the apparent complexity of a subsystem, by exposing a simpler interface.
 Hide multiple tightly coupled subcomponents behind a single object or method.
 -URLSession: A system that fetches a resource based on its URLRequest
 -Cache: The subsystem responsible for storing the results of the resource fetcher
 -CacheCleaner: The subsystem responsible for periodically running over the cache and actively removing stale data
 */

/*
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
*/

// MARK: - Decorator Pattern
/**
 Allows to add behaviors to objects without changing their structure or inheritance chain.
 Instead of subclassing, decorators enhance an object's behavior by adding functionalities
 */

 /*
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

 */
 
// MARK: - Builder Pattern
/**
 An abstract way the construction of objects or values that require a large number of parameters by using an intermediate representation.
 */

/*
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
*/

// MARK: - Refreshing The Basics

/*
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
*/

/*
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
*/

/*
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

*/

/*
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
*/


/*
 func returnAny(randomType: Any) -> Any {
     return randomType
 }

 returnAny(randomType: "Hello World")
 print(type(of: returnAny(randomType: "Hello World")))
 returnAny(randomType: 123)
 print(type(of: returnAny(randomType: 123)))

 let arr = ["A", "B", "C", "D", "F", "U"]
 */

/*
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
*/

// MARK: - Closure
/*
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
*/

// MARK: - Protocol
/*
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
*/

