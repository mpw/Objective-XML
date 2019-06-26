//
//  main.swift
//  swiftdecoder
//
//  Created by Marcel Weiher on 26.06.19.
//

import Foundation

struct TestClass : Decodable {
    let hi:Int
    let there:Int
    let comment:String

}


NSLog("Swift Coding")
let coder=JSONDecoder()
let filename=CommandLine.arguments[1]
let data = try! Data(contentsOf: URL(fileURLWithPath: filename))
print("filename: \(filename)")
print("data: \(data.count)")
let decoded = try! coder.decode( [TestClass].self, from: data)
print("decoded count: \(decoded.count)")

