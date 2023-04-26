//
//  Dependencies.swift
//  Config
//
//  Created by Dean Chung on 2023/4/26.
//

import ProjectDescription

let packages: SwiftPackageManagerDependencies = [
  .remote(url: "https://github.com/ReactiveX/RxSwift.git",
          requirement: .exact(.init(6, 2, 0))),
]

let dependencies = Dependencies(
    carthage: [],
    swiftPackageManager: packages,
    platforms: [.iOS]
)
