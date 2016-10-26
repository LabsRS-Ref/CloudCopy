import PackageDescription

let package = Package(
    name: "CloudCopy",
    dependencies: [
        .Package(url: "https://github.com/coodly/swlogger.git", Version(0, 3, 1)),
        .Package(url: "https://github.com/coodly/TalkToCloud.git", Version(0, 4, 0)),
    ]
)
