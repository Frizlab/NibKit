// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "NibKit",
	products: [
		.library(name: "NibKit", targets: ["NibKit"])
	],
	dependencies: [
		.package(url: "https://github.com/Frizlab/stream-reader.git", from: "3.2.3")
	],
	targets: [
		.target(name: "NibKit", dependencies: [
			.product(name: "StreamReader", package: "stream-reader")
		]),
		.testTarget(name: "NibKitTests", dependencies: ["NibKit"])
	]
)
