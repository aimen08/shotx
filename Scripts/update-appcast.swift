#!/usr/bin/env swift
import Foundation

guard CommandLine.arguments.count >= 5 else {
    FileHandle.standardError.write(Data(
        "Usage: update-appcast.swift <version> <dmg-url> <signature> <length>\n".utf8
    ))
    exit(1)
}

let version = CommandLine.arguments[1]
let dmgURL = CommandLine.arguments[2]
let signature = CommandLine.arguments[3]
let length = CommandLine.arguments[4]

let formatter = DateFormatter()
formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(identifier: "GMT")
let pubDate = formatter.string(from: Date())

let newItem = """
        <item>
            <title>Version \(version)</title>
            <pubDate>\(pubDate)</pubDate>
            <sparkle:version>\(version)</sparkle:version>
            <sparkle:shortVersionString>\(version)</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
            <enclosure url="\(dmgURL)" length="\(length)" type="application/octet-stream" sparkle:edSignature="\(signature)" />
        </item>
"""

let appcastPath = "appcast.xml"
let url = URL(fileURLWithPath: appcastPath)

if let existing = try? String(contentsOf: url),
   let range = existing.range(of: "</language>") {
    let insertion = "</language>\n\n\(newItem)"
    let updated = existing.replacingCharacters(in: range, with: insertion)
    try updated.write(to: url, atomically: true, encoding: .utf8)
} else {
    let template = """
<?xml version="1.0" standalone="yes"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>ShotX Updates</title>
        <link>https://raw.githubusercontent.com/aimen08/shotx/main/appcast.xml</link>
        <description>Updates for ShotX</description>
        <language>en</language>

\(newItem)
    </channel>
</rss>
"""
    try template.write(to: url, atomically: true, encoding: .utf8)
}

print("✓ appcast.xml updated with v\(version)")
