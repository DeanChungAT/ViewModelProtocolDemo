//
//  MockViewModel.swift
//  AmazingTalkerTests
//
//  Created by AlexPan on 2023/4/25.
//
// swiftlint:disable force_cast

import Foundation
import RxSwift
@testable import ViewModelProtocolDemo

class MockViewModel: ViewModelProtocol {

  var switchSchedulerType1: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInteractive)
  var switchSchedulerType2: ImmediateSchedulerType = MainScheduler.instance

  var stateBehaviorRelayController: BehaviorRelayController<State>

  var schedulerType: ImmediateSchedulerType = SerialDispatchQueueScheduler(qos: .background)

  required init(environment: Environment,
                initialState: State) {
    self.environment = environment
    self.stateBehaviorRelayController = .init(.init(value: initialState))
  }

  func mutate(action: Action) -> Observable<Mutation> {
    print("debug - Thread.current 1 = \(Thread.current)")
    switch action {
    case .appendStrings:
      return .concat([
        .create({ event in
          DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else { return }
            print("debug - Thread.current 2 = \(Thread.current)")
            let next = (self.stateBehaviorRelayController.value().strings.last ?? "") + "bbb"
            event.on(.next(.appendStrings(next)))
            event.onCompleted()
          }
          return Disposables.create()
        }),
        .create({ event in
          DispatchQueue.main.sync { [weak self] in
            guard let self else { return }
            print("debug - Thread.current 3 = \(Thread.current)")
            let next = (self.stateBehaviorRelayController.value().strings.last ?? "") + "ccc"
            event.on(.next(.appendStrings(next)))
            event.onCompleted()
          }
          return Disposables.create()
        }),
        .create({ event in
          DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            print("debug - Thread.current 4 = \(Thread.current)")
            let next = (self.stateBehaviorRelayController.value().strings.last ?? "") + "ddd"
            event.on(.next(.appendStrings(next)))
            event.onCompleted()
          }
          return Disposables.create()
        }),
        .create({ event in
          DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            print("debug - Thread.current 5 = \(Thread.current)")
            let next = (self.stateBehaviorRelayController.value().strings.last ?? "") + "eee"
            event.on(.next(.appendStrings(next)))
            event.onCompleted()
          }
          return Disposables.create()
        })
      ]).observe(on: schedulerType)
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    print("debug - Thread.current 4 = \(Thread.current)")
    var newState = state
    switch mutation {
    case let .appendStrings(text):
      newState.strings.append(text)
      for _ in 0...1000 {
        let text1 = Date().timeString(ofStyle: .medium)
        newState.strings1.append(text1)
        let text2 = Date().timeString(ofStyle: .medium)
        newState.strings2.append(text2)
        let text3 = Date().timeString(ofStyle: .medium)
        newState.strings3.append(text3)
        let text4 = Date().timeString(ofStyle: .medium)
        newState.strings4.append(text4)
      }
    }
    return newState
  }

  enum Action {
    case appendStrings
  }

  enum Mutation {
    case appendStrings(String)
  }

  private let environment: Environment

  struct State: Equatable {
    var strings: [String] = ["aaa"]
    var strings1: [String] = Self.mockStrings()
    var strings2: [String] = Self.mockStrings()
    var strings3: [String] = Self.mockStrings()
    var strings4: [String] = Self.mockStrings()

    static func mockStrings() -> [String] {
      var strings: [String] = []
      for _ in 0...1000000 {
        strings.append(UUID().uuidString)
      }
      return strings
    }
  }

  class Environment {}
  typealias ActionError = Error

}

extension Date {
  func timeString(ofStyle style: DateFormatter.Style = .medium) -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.timeStyle = style
      dateFormatter.dateStyle = .none
      return dateFormatter.string(from: self)
  }
}
