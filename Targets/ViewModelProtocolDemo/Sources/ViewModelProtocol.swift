//
//  ViewModelProtocol.swift
//  AmazingTalker
//
//  Created by 潘皓群 on 2022/6/9.
//  Copyright © 2022 AmazingTalker. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public protocol ViewModelProtocol: AnyObject {

  associatedtype Action
  associatedtype Mutation
  associatedtype State
  associatedtype Environment
  associatedtype ActionError: Error

  var stateBehaviorRelayController: BehaviorRelayController<State> { get set }
  var schedulerType: ImmediateSchedulerType { get }

  init(environment: Environment, initialState: State)
  func mutate(action: Action) -> Observable<Mutation>
  func reduce(state: State, mutation: Mutation) -> State

}

public extension ViewModelProtocol {

  var stateObservable: Observable<State> {
    stateBehaviorRelayController
      .asObservable()
      .subscribe(on: schedulerType)
  }

  func send(action: Action) -> Completable {
    let action = Observable<Action>.just(action).observe(on: schedulerType)
    let mutation = action
      .flatMap { [weak self] action -> Observable<Mutation> in
        guard let self = self else { return .empty() }
        return self.mutate(action: action)
      }
    let state = mutation
      .flatMap { [weak self] mutation -> Observable<State> in
        guard let self = self else { return .empty() }
        return .just(self.reduce(state: self.stateBehaviorRelayController.value(), mutation: mutation))
      }
      .do(onNext: { [weak self] newState in
        guard let self = self else { return }
        self.stateBehaviorRelayController.accept(newState)
      })
      .ignoreElements()
      .asCompletable()
    return state
  }
}

public class BehaviorRelayController<Element> {

  private let baseMessage = "ViewController should not call %@, please use ViewModel's %@"
  private let behaviorRelay: BehaviorRelay<Element>

  init(_ behaviorRelay: BehaviorRelay<Element>,
       _ filePath: String = #filePath,
       _ bundle: Bundle = .main) {
    self.behaviorRelay = behaviorRelay
    if checkIsFromViewController(filePath, bundle) {
        fatalError("\(type(of: self)) can only use in ViewModel!")
    }
  }

  func accept(_ event: Element,
              _ filePath: String = #filePath,
              _ bundle: Bundle = .main) {
    if checkIsFromViewController(filePath, bundle) {
      let message: String = .init(format: baseMessage, #function, "send(action: Action) instead!")
      fatalError(message)
    }
    behaviorRelay.accept(event)
  }

  func asObservable(_ filePath: String = #filePath,
                    _ bundle: Bundle = .main) -> Observable<Element> {
    if checkIsFromViewController(filePath, bundle) {
      let message: String = .init(format: baseMessage, #function, "observable instead!")
      fatalError(message)
    }
    return behaviorRelay.asObservable()
  }

  func value(_ filePath: String = #filePath,
             _ bundle: Bundle = .main) -> Element {
    if checkIsFromViewController(filePath, bundle) {
      let message: String = .init(format: baseMessage, #function, "currentState instead!")
      fatalError(message)
    }
    return behaviorRelay.value
  }

  private func checkIsFromViewController(_ filePath: String,
                                         _ bundle: Bundle) -> Bool {
    guard let bundleName = bundle.infoDictionary!["CFBundleExecutable"] as? String,
          let result = filePath.components(separatedBy: "/").last else { return false }
    let className: String = result.replacingOccurrences(of: ".swift", with: "")
    let fullClassName = "\(bundleName).\(className)"
    guard let objectType = NSClassFromString(fullClassName), objectType is UIViewController.Type else { return false }
    return true
  }

}
