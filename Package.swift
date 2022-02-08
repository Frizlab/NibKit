// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "NibKit",
	products: [
		.library(name: "NibKit", targets: ["NibKit"])
	],
	targets: [
		.target(name: "NibKit"),
		.testTarget(name: "NibKitTests", dependencies: ["NibKit"])
	]
)
