//
//  ViewModelProtocolTests.swift
//  AmazingTalkerTests
//
//  Created by AlexPan on 2023/4/25.
//

import RxBlocking
import XCTest
@testable import ViewModelProtocolDemo
import RxSwift

final class ViewModelProtocolTests: XCTestCase {

  func testExample() throws {
    let viewModel = MockViewModel(environment: .init(), initialState: .init())
    let checkCount = 5
    let expectation = expectation(description: "checkCount equals \(checkCount)")
    viewModel.stateObservable.take(checkCount)
      .map(\.strings)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] strings in
        self?.count += 1
        print("debug - state = \(strings)")
        if self?.count == checkCount {
          XCTAssertEqual(strings, ["aaa", "aaabbb", "aaabbbccc", "aaabbbcccddd", "aaabbbcccdddeee"])
          expectation.fulfill()
        }
      }).disposed(by: disposeBag)

    _ = viewModel.send(action: .appendStrings)
      .subscribe()
      .disposed(by: disposeBag)

    wait(for: [expectation], timeout: 1000)

  }

  var count: Int = 0
  var disposeBag: DisposeBag = .init()

}
