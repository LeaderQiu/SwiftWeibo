// Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

var s = "0x1f61f"
var val: Int32 = 0x1f603

// 文本扫描，查找特殊的字符串，有些简单的正则，可以使用 NSScanner 来实现

// 1. 实例化一个文本扫描
var scanner = NSScanner(string: s)

// 2. 在字符串中扫描十六整数
// UNICode -> 涵盖了全世界所有的字符集
// UTF8 是 UNICode 的一个子集
// 使用 1~4个字节，表示一个特殊的符号

var value: UInt32 = 0
scanner.scanHexInt(&value)
let ss = "\(Character(UnicodeScalar(value)))"


var 老 = 100
var 小 = 20
let 结果 = 老 - 小







